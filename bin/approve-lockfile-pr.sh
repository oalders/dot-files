#!/usr/bin/env bash

set -e -u -o pipefail -x

remote=$1
branch=$2

git fetch "$remote"
file=/tmp/diff.txt

echo '```' > $file

script=~/Documents/github/oalders/diff-lockfiles/bin/diff-lockfiles.js

node $script \
    --format table \
    "$remote"/main "$remote/$branch" >> /tmp/diff.txt

echo '```' >> $file

node $script \
    --format table \
    --color \
    "$remote"/main "$remote/$branch"

read -n 1 -s -r -p "Approve PR? Press any key to continue. ctrl-c to exit."

gh pr review --approve "$branch" -F $file
gh pr merge --merge "$branch"
