#!/usr/bin/env bash

set -eu -o pipefail

author=${1:-"app/dependabot"}
label=${2:-""}

gh_command="gh pr list --author \"$author\" --json headRefName"
if [ -n "$label" ]; then
    gh_command="$gh_command --label \"$label\""
fi

# xargs requires -o because we are running an interactive application
eval "$gh_command" |
    jq '.[].headRefName' |
    fzf |
    xargs -n 1 -o approve-lockfile-pr.sh origin
