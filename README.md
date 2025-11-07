# GitHub 2 Markdown

Backup all your GitHub issues in an easy so search format.

## Features

- _Simple:_ Uses only basic command-line tools (`bash`, `curl`, `jq`) — lightweight and easy to inspect or tweak.
- _Reliable:_ Supports GitHub authentication which prevents rate limiting errors.
- _Complete:_ Saves each issue including comments in a separate file.

## Goals

- _Own Your Data:_ Keep every issue backed up offline so your valuable work stays accessible — even if GitHub disappears.
- _Search Faster:_ Blaze through plain-text files locally instead of waiting on sluggish web interfaces.
- _Automate Exports:_ Let scripts handle backups on schedule. No more tedious and error-prone manual exports.
- _Search Everywhere:_ Store everything locally in plain text and search it all at once — no more hunting for where to even start searching, no context switches, no wasted time and energy.

## Requirements

- bash
- curl
- jq

## Installation

Make the program executable from everywhere.

```bash
git clone https://github.com/skepticspriggan/github2markdown.git
cd github2markdown
make install
```

Schedule a periodic export at 10:00 on every 7th day of the month.

```bash
crontab -l | cat - <(echo "0 10 */7 * * $HOME/.local/bin/github2markdown --username skepticspriggan --destination $HOME/repos/issues") \
  | crontab -
```

## Usage

Run the script with your GitHub username:

```bash
github2markdown --username USERNAME
```

Issues are stored to a directory called `issues` by default.

Store the issues in `~/repos/issues` instead:

```bash
github2markdown --username USERNAME --destination ~/repos/issues
```

Store many issues reliably by using a GitHub access token safely passed with [`pass`](https://www.passwordstore.org/):

```bash
github2markdown --username USERNAME --token $(pass github/token)
```

## Todo

- Support pagination
- Filter noise by bots
