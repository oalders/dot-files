#!/usr/bin/env bash

set -eu -o pipefail

# Kill the running tmux server
if tmux has-session 2>/dev/null; then
    echo "Killing tmux server..."
    tmux kill-server
    echo "✓ Tmux server killed"
else
    echo "No tmux server running"
fi

# Delete tmux resurrect last symlink
resurrect_last="$HOME/.cache/tmux/resurrect/last"
if [ -L "$resurrect_last" ]; then
    echo "Deleting tmux resurrect last symlink..."
    rm "$resurrect_last"
    echo "✓ Deleted $resurrect_last"
elif [ -e "$resurrect_last" ]; then
    echo "Warning: $resurrect_last exists but is not a symlink"
else
    echo "No resurrect last symlink found at $resurrect_last"
fi

echo "Done!"
