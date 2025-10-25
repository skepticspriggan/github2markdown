# GitHub 2 Markdown

Stores GitHub issues of an author in simple human readable, plain text markdown files.

## Features

- _Simple:_ Only uses basic command-line tools (`bash`, `curl`, `jq`.)
- _Reliable:_ Supports GitHub authentication which prevents rate limiting errors.
- Saves each issue including comments in a separate file.

## Goals

- _Availabilty/Data Ownership:_ Keeping issues backup offline ensures the value information therein remains available even if the repositories are no longer accessible online.
- _Fast Search:_ Searching and viewing offline plain-text files is much faster compared to the online GitHub interface.
- _Automation:_ Periodic exports maintain an up-to-date backup of all personal issues. It is time intensive and error prone to manually backup issues.
- _Global Search:_ One search tool to rule them all. Storing all information locally in plain-text files allows one to search in a single place instead of in many different slow and unreliable online places.

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
