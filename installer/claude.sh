#!/bin/bash

set -euxo pipefail

# Pin the Claude Code binary. DISABLE_AUTOUPDATER=1 (set in bin/nn) holds this
# at runtime; passing the version here holds it at install time so re-runs of
# this installer don't silently upgrade to latest.
CLAUDE_VERSION=2.1.210

if ! is there claude; then
    tmpscript=$(mktemp)
    trap 'rm -f "$tmpscript"' EXIT
    curl -fsSL -o "$tmpscript" https://claude.ai/install.sh
    bash "$tmpscript" "$CLAUDE_VERSION"
elif is cli version claude ne "$CLAUDE_VERSION"; then
    claude install "$CLAUDE_VERSION"
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

if ! is there claude-swap; then
    uv tool install claude-swap
fi
