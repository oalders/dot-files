#!/usr/bin/env bash

set -e -u -o pipefail -x

remote=$1
branch=$2

gh pr checks "$branch"

git fetch "$remote"
file=/tmp/diff.txt

echo '```' >$file

script=diff-lockfiles

$script \
    --format table \
    "$remote"/main "$remote/$branch" >>/tmp/diff.txt

echo '```' >>$file

$script \
    --format table \
    --color \
    "$remote"/main "$remote/$branch"

read -n 1 -t 30 -s -r -p "Approve PR? Press y to continue, r to rebase, n to exit." input

if [[ $input == "y" ]]; then
    gh pr review --approve "$branch" -F $file
    gh pr merge --merge "$branch"
elif [[ $input == "r" ]]; then
    dependabot-rebase.sh "$branch"
else
    echo "Input was neither y nor r. Exiting."
fi
