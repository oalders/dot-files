#!/usr/bin/env bash

set -eu -o pipefail

# xargs requires -o because we are running an interactive application
gh pr list --author "app/dependabot" --json headRefName |
    jq '.[].headRefName' |
    fzf |
    xargs -n 1 -o approve-lockfile-pr.sh origin
