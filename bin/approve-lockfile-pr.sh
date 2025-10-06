#!/usr/bin/env bash

set -eu -o pipefail

author=${1:-"app/dependabot"}
label=${2:-""}

gh_command="gh pr list --author \"$author\" --json headRefName"
if [ -n "$label" ]; then
    gh_command="$gh_command --label \"$label\""
fi

# Select branch with fzf
branch=$(eval "$gh_command" | jq -r '.[].headRefName' | fzf)

if [ -z "$branch" ]; then
    echo "No branch selected. Exiting."
    exit 1
fi

# Merged functionality from approve-lockfile-pr.sh
remote="origin"

gh pr view "$branch"
gh pr checks "$branch"

# Check if main branch exists, otherwise use master
if git show-ref --verify --quiet refs/heads/main; then
    base_branch="main"
else
    base_branch="master"
fi

# Fetch only the specific branches we need for diffing
echo "Fetching branches for comparison..."
git fetch origin "$base_branch" "$branch" || true

script=diff-lockfiles

# Check if diff-lockfiles command exists
is there $script || {
    echo "Error: $script command not found. Please install it first."
    exit 1
}

$script \
    --format table \
    --color \
    "$remote"/"$base_branch" "$remote/$branch"

read -n 1 -t 30 -s -r -p "Approve PR? Press y to continue, r to rebase, n to exit." input

if [[ $input == "y" ]]; then
    file=$(mktemp)
    $script \
        --format markdown \
        "$remote"/"$base_branch" "$remote/$branch" >$file

    gh pr review --approve "$branch" -F $file
    gh pr merge --merge --delete-branch "$branch" || gh pr merge "$branch" --auto
elif [[ $input == "r" ]]; then
    dependabot-rebase.sh "$branch"
else
    echo "Input was neither y nor r. Exiting."
fi
