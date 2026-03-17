#!/usr/bin/env bash

set -eu -o pipefail

if [ $# -gt 0 ]; then
    branch=$1
else
    branch=$(gh pr list --author "app/dependabot" --json headRefName | jq -r '.[].headRefName' | fzf)

    if [ -z "$branch" ]; then
        echo "No branch selected. Exiting."
        exit 1
    fi
fi

gh pr comment "$branch" -b '@dependabot rebase'
