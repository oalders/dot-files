#!/usr/bin/env bash

# Ruby installer

set -eu -o pipefail

if is os name ne darwin; then
    exit 0
fi

tmpscript=$(mktemp)
trap 'rm -f "$tmpscript"' EXIT
\curl -sSL -o "$tmpscript" https://get.rvm.io
bash "$tmpscript"

# Possibly:
# brew link --overwrite coreutils

# Usage:
# rvm install 2.7
# rvm list
# rvm use 2.7.1

exit 0
