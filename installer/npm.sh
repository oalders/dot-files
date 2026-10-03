#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

target_version=24

# Minimum full version, not just the major. Recent npm releases refuse to run
# on older 24.x builds (npm 12 wants ^24.15.0), so a major-only check would
# leave a stale node in place and every npm command would warn.
min_version=24.15.0
if is os name eq linux && is there apt && (! is there node || is cli version node lt $min_version) && is user sudoer; then
    tmpscript=$(mktemp)
    trap 'rm -f "$tmpscript"' EXIT
    curl -sL -o "$tmpscript" https://deb.nodesource.com/setup_$target_version.x
    sudo -E bash "$tmpscript"
    sudo apt-get install -y nodejs
fi

# Without a default, fnm errors on every cd outside a project with an engines pin.
if is there fnm && ! fnm list | grep -q default; then
    fnm default system
fi

debounce --local 1 d npm install npm@latest
debounce --local 1 d npm install

# npm 12 skipped the binary download before allowScripts listed tree-sitter-cli,
# and npm install won't retry it for an already-installed package.
if ! node_modules/.bin/tree-sitter --version >/dev/null 2>&1; then
    npm rebuild tree-sitter-cli
fi

if [[ $IS_GITHUB == false ]] && is os name eq darwin; then
    mkdir -p "$HOME/.npm-packages/lib"
    npx --yes npm-merge-driver install --global
fi

exit 0
