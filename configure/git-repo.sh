#!/usr/bin/env bash

set -eu

# Set branch to $1 if it's defined, otherwise capture the output of a shell command
branch=${1:-$(git symbolic-ref --short refs/remotes/origin/HEAD | cut -d'/' -f2)}

if [ "$branch" = "" ]; then
    if [ -f ".git/refs/remotes/origin/main" ]; then
        branch="main"
    else
        echo "cannot find main branch name"
        exit 1
    fi
fi

echo "Setting main branch in local Git aliases to \"$branch\""

git config alias.dom "diff -w -M --relative origin/$branch...HEAD"
git config alias.doms "diff -w -M --relative origin/$branch...HEAD --stat"
git config alias.domo "diff -w -M --relative origin/$branch...HEAD --name-only"
git config alias.from "!git fetch -p; git rebase origin/$branch"
git config alias.prom "pull --rebase origin $branch"
