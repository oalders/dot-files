#!/bin/bash

BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD | cut -d'/' -f2)

echo "Setting main branch in local Git aliases to \"$BRANCH\""

git config alias.dom "diff -w -M origin/$BRANCH...HEAD"
git config alias.doms "diff -w -M origin/$BRANCH...HEAD --stat"
git config alias.domo "diff -w -M origin/$BRANCH...HEAD --name-only"
git config alias.from "!git fetch -p; git rebase origin/$BRANCH"
git config alias.prom "pull --rebase origin $BRANCH"
