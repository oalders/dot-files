#!/usr/bin/env bash

set -eux -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

echo "git config"

# Static settings live in ~/dot-files/git/; ~/.gitconfig is a stub that includes
# them. Every write to ~/.gitconfig swaps its inode, which revokes read access in
# running nono sessions, so only write when something actually changes.

gset() {
    local key=$1 val=$2
    [[ "$(git config --global --get "$key" || true)" == "$val" ]] && return 0
    git config --global "$key" "$val"
}

ginclude() {
    local path=$1
    git config --global --get-all include.path | grep -qxF "$path" && return 0
    git config --global --add include.path "$path"
}

# shellcheck disable=SC2088 # git expands ~ in include.path
shared='~/dot-files/git/config'
# shellcheck disable=SC2088
darwin='~/dot-files/git/config-darwin'

# One-time migration: drop keys that used to be written directly into
# ~/.gitconfig and now come from the includes.
if ! git config --global --get-all include.path | grep -qxF "$shared"; then
    for key in $(for f in ~/dot-files/git/config*; do
        git config -f "$f" --name-only --list
    done | sort -u); do
        git config --global --unset-all "$key" || true
    done
fi

# Aliases all live in git/config, so any left in the stub are stale (the
# migration above misses ones since removed from git/config) and would shadow it.
if git config --global --get-regexp '^alias\.' >/dev/null; then
    git config --global --remove-section alias
fi

ginclude "$shared"

# Meld is configured only via `open -a`, so it's macOS-only.
if is os name eq darwin && [ -d '/Applications/Meld.app' ]; then
    ginclude "$darwin"
fi

# Versioned hooks; core.hooksPath replaces .git/hooks entirely.
if [[ "$(git -C ~/dot-files config --local --get core.hooksPath || true)" != .githooks ]]; then
    git -C ~/dot-files config core.hooksPath .githooks
fi

if is cli version git gte 2.35; then
    gset merge.conflictstyle zdiff3
else
    gset merge.conflictstyle diff3
fi

if is os id ne debian; then
    gset core.pager 'delta'
    gset interactive.diffFilter 'delta --color-only'
else
    gset core.pager 'less'
fi

if git config --global --get branch.master.merge >/dev/null; then
    git config --global --unset branch.master.merge
fi

# Requires git-lfs to have been installed
if ! is there git-lfs; then
    if is os name eq linux; then
        if is var IS_SUDOER true; then
            sudo apt-get install -y git-lfs
        fi
    fi
fi
if is there git-lfs && ! git config --global --get filter.lfs.process >/dev/null; then
    git lfs install --skip-repo
fi

exit 0
