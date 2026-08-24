#!/bin/bash

set -euxo pipefail

# Pin the Claude Code binary. DISABLE_AUTOUPDATER=1 (set in bin/nn) holds this
# at runtime; passing the version here holds it at install time so re-runs of
# this installer don't silently upgrade to latest.
CLAUDE_VERSION=2.1.237

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
    # Don't let the installer append `. "$HOME/.local/bin/env"` to the shell rc
    # files. Those are symlinks into this repo (created earlier by symlinks.sh),
    # so on a fresh box the installer would write through the symlink and leave
    # bashrc/bash_profile/profile dirty in the working tree. PATH for the rest
    # of this script is handled below, and bashrc already adds ~/.local/bin via
    # `add_path`, so the env shim is redundant anyway. UV_NO_MODIFY_PATH is the
    # current knob; INSTALLER_NO_MODIFY_PATH is kept for older installer builds.
    UV_NO_MODIFY_PATH=1 INSTALLER_NO_MODIFY_PATH=1 sh "$tmpscript"
fi

export PATH="$HOME/.local/bin:$PATH"

if ! is there serena; then
    uv tool install git+https://github.com/oraios/serena@v0.1.4
fi

if ! is there claude-swap; then
    uv tool install claude-swap
fi
