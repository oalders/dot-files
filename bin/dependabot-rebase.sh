#!/usr/bin/env bash

set -e -u -x -o pipefail

branch=$1

gh pr comment $branch -b '@dependabot rebase'
