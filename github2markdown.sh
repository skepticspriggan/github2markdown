#!/usr/bin/env bash

# set -euxo pipefail

usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS]

Stores github issues of an author in markdown.

Options:
  -u, --username USERNAME
        The username of the issue author.

  --token TOKEN
        The github access token used in the API requests.
        The benefit is less rate limiting errors.

  --destination DESTINATION
        The directory in which the issues are stored.

  -t, --template TEMPLATE
        Template for generating filenames.
        Available placeholders:
          {number}
          {title}
          {repo}
          {state}  open or closed
          {type}   Issue or Pull Request
        Example: --template "{repo}-{number}"

  -h, --help    Show this help message and exit

  -d, --debug   Show debug messages and limit query results

Examples:
  # Use github token
  ${0##*/} --username foobar \\
    --token \$(pass github/token) \\

  # Set filename template
  ${0##*/} --username foobar \\
    --template "{type}-{number}"

  # Set destination directory
  ${0##*/} --username foobar \\
    --destination \$HOME/repos/issues
EOF
}

long="username:,token:,destination:,template:,help,debug"

options=$(getopt -o u:t:hd --long $long --name "${0##*/}" -- "$@") || exit 1
if [ "$?" != "0" ]; then
  usage
fi

eval set -- "$options"

username=""
token=""
destination="issues"
template="{repo}-{number}"
debug=0

while true; do
  case "$1" in
    -u|--username)
      username="$2"
      shift 2
      ;;
    --token)
      token="$2"
      shift 2
      ;;
    --destination)
      destination="$2"
      shift 2
      ;;
    -t|--template)
      template="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -d | --debug)
      debug=1
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$username" ]; then
  echo "The username is required" >&2
  echo
  usage
  exit 1
fi

if [ $debug == 1 ]; then
  set -euxo pipefail
  echo "parsed arguments: $parsed"
fi

mkdir -p "$destination"

issues_url="https://api.github.com/search/issues?q=author:$username"
if  [ $debug == 1 ]; then
  issues_url+="&per_page=2"
fi

headers=(
  "--header" "Accept: application/vnd.github+json"
  "--header" "X-GitHub-Api-Version: 2022-11-28"
)

if [ -n "$token" ]; then
  headers+=("--header" "Authorization: token $token")
fi

response=$(curl --silent --location "${headers[@]}" "$issues_url")

if echo "$response" | grep -q "rate limit exceeded"; then
  echo "GitHub API rate limit exceeded. Authenticate to increase rate limit." >&2
  exit 1
fi

count=$(echo "$response" | jq '.items | length')
echo "Found $count issues by $username."
echo

echo "$response" | jq -c '.items[]' | while read -r item; do
  number=$(echo "$item" | jq -r '.number // empty')
  title=$(echo "$item" | jq -r '.title')
  state=$(echo "$item" | jq -r '.state')
  html_url=$(echo "$item" | jq -r '.html_url')
  comments_url=$(echo "$item" | jq -r '.comments_url')
  reviews_url="$(echo "$item" | jq -r '.pull_request.url')/comments"
  repo=$(echo "$item" | jq -r '.repository_url | split("/")[-1]')
  created=$(echo "$item" | jq -r '.created_at | sub("T"; " ") | sub("Z"; "")')
  body=$(echo "$item" | jq -r '.body // ""' | tr -d '\r' | sed "s/✔️/y/g" | sed "s/❌/n/g")
  is_pr=$(echo "$item" | jq -r '.pull_request? | if . != null then true else false end')

  type="Issue"
  [[ "$is_pr" == "true" ]] && type="Pull Request"

  safe_title=$(echo "$title" | tr -cd '[:alnum:]-_' | cut -c1-50)
  filename=$(echo "$template" |
    sed "s/{number}/$number/" |
    sed "s/{title}/$title/" |
    sed "s/{repo}/$repo/" |
    sed "s/{state}/$state/" |
    sed "s/{type}/$type/")
  path="$destination/${filename}.md"

  cat > "$path" <<EOF
# [$title]($html_url)

- _Type:_ $type
- _State:_ $state
- _Repository:_ \`$repo\`
- _Created at:_ $created

$body
EOF
  echo "- $type #$number $title in $repo"
  response=$(curl --silent --location "${headers[@]}" "$comments_url")

  if echo "$response" | grep -q "rate limit exceeded"; then
    echo "GitHub API rate limit exceeded. Authenticate to increase rate limit." >&2
    exit 1
  fi

  if jq -e 'length > 0' <<< "$response" >/dev/null; then
    cat >> "$path" <<EOF

## Comments
EOF
    echo "$response" | jq -c '.[]' | while read -r comment; do
      user=$(echo "$comment" | jq -r '.user.login')

      # Filter noise from bots
      if [[ "$user" == *"[bot]"* ]]; then
        continue
      fi

      created_at_iso=$(echo "$comment" | jq -r '.created_at')
      created_at=$(date -u -d "$created_at_iso" +"%Y-%m-%d %H:%M")
      body=$(echo "$comment" | jq -r '.body' | tr -d '\r' | sed 's/^/> /')
      cat >> "$path" <<EOF

$user on $created_at

$body
EOF
    done
  fi

  response=$(curl --silent --location "${headers[@]}" "$reviews_url")

  if echo "$response" | grep -q "rate limit exceeded"; then
    echo "GitHub API rate limit exceeded. Authenticate to increase rate limit." >&2
    exit 1
  fi

  if jq -e 'length > 0' <<< "$response" >/dev/null; then
    cat >> "$path" <<EOF

## Reviews
EOF
    echo "$response" | jq -c '.[]' | while read -r review; do
      user=$(echo "$review" | jq -r '.user.login')
      created_at_iso=$(echo "$review" | jq -r '.created_at')
      created_at=$(date -u -d "$created_at_iso" +"%Y-%m-%d %H:%M")
      body=$(echo "$review" | jq -r '.body' | tr -d '\r' | sed 's/^/> /')
      review_path=$(echo "$review" | jq -r '.path')
      diff_hunk=$(echo "$review" | jq -r '.diff_hunk')
      fence='```'
      cat >> "$path" <<EOF

$user on $created_at

$review_path

$fence
$diff_hunk
$fence

$body
EOF
    done
  fi

done
