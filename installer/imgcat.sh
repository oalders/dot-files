#!/usr/bin/env bash

set -eu -o pipefail

if ! is there imgcat; then
    file="$HOME/local/bin/imgcat"
    curl https://iterm2.com/utilities/imgcat --output "$file"
    chmod 755 "$file"
fi
