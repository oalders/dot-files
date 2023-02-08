#!/usr/bin/env bash

set -eu

BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD | cut -d'/' -f2)

if [ "$BRANCH" = "" ]; then
    if [ -f ".git/refs/remotes/origin/main" ]; then
        BRANCH="main"
    else
        echo "cannot find main branch name"
        exit 1
    fi
fi

echo "Setting main branch in local Git aliases to \"$BRANCH\""

git config alias.dom "diff -w -M origin/$BRANCH...HEAD"
git config alias.doms "diff -w -M origin/$BRANCH...HEAD --stat"
git config alias.domo "diff -w -M origin/$BRANCH...HEAD --name-only"
git config alias.from "!git fetch -p; git rebase origin/$BRANCH"
git config alias.prom "pull --rebase origin $BRANCH"
