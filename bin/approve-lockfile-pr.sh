#!/usr/bin/env bash

set -e -u -o pipefail -x

remote=$1
branch=$2

gh pr view "$branch"
gh pr checks "$branch"

gh repo sync
gh repo sync -b "$branch" --force
git fetch origin || true

# Check if main branch exists, otherwise use master
if git show-ref --verify --quiet refs/heads/main; then
    base_branch="main"
else
    base_branch="master"
fi

git pull --rebase origin "$base_branch" || true
file=/tmp/diff.txt

echo '```' >$file

script=diff-lockfiles

$script \
    --format table \
    "$remote"/"$base_branch" "$remote/$branch" >>/tmp/diff.txt

echo '```' >>$file

$script \
    --format table \
    --color \
    "$remote"/"$base_branch" "$remote/$branch"

read -n 1 -t 30 -s -r -p "Approve PR? Press y to continue, r to rebase, n to exit." input

if [[ $input == "y" ]]; then
    gh pr review --approve "$branch" -F $file
    gh pr merge --merge "$branch" || gh pr --merge "$branch" --auto
elif [[ $input == "r" ]]; then
    dependabot-rebase.sh "$branch"
else
    echo "Input was neither y nor r. Exiting."
fi
