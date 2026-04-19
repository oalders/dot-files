#!/bin/bash

set -euxo pipefail

if ! is there claude; then
    tmpscript=$(mktemp)
    trap 'rm -f "$tmpscript"' EXIT
    curl -fsSL -o "$tmpscript" https://claude.ai/install.sh
    bash "$tmpscript"
else
    claude install
fi

if ! is there uv; then
    tmpscript=$(mktemp)
    trap 'rm -f "$tmpscript"' EXIT
    curl -LsSf -o "$tmpscript" https://astral.sh/uv/install.sh
    sh "$tmpscript"
fi

export PATH="$HOME/.local/bin:$PATH"

if ! is there serena; then
    uv tool install git+https://github.com/oraios/serena@v0.1.4
fi
