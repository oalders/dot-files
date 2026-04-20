#!/usr/bin/env bash

set -eu -o pipefail

if is os id eq almalinux; then
    exit
fi

PREFIX=~/dot-files

# shellcheck source=bash_functions.sh
source $PREFIX/bash_functions.sh
add_path "$HOME/local/bin"

set -x

./installer/tmux.sh

ln -sf $PREFIX/tmux.conf ~/.tmux.conf

# tpack is a drop-in replacement for TPM with proper version pin support.
# It uses the same ~/.tmux/plugins/tpm directory for backward compatibility.
TPACK_DIR=~/.tmux/plugins/tpm
TPACK_REPO=https://github.com/tmuxpack/tpack
if [ ! -d $TPACK_DIR ]; then
    git clone --depth 1 "$TPACK_REPO" "$TPACK_DIR"
elif ! git -C "$TPACK_DIR" remote get-url origin | grep -q tmuxpack/tpack; then
    # Migrate from TPM to tpack by swapping the remote
    git -C "$TPACK_DIR" remote set-url origin "$TPACK_REPO"
    git -C "$TPACK_DIR" fetch origin
    git -C "$TPACK_DIR" reset --hard origin/main
fi

# tmux needs to be running in order to source a config file etc
# Also clean up an old CI sessions
session_name='CI'
if tmux has-session -t $session_name; then
    tmux kill-session -t $session_name
fi
tmux new-session -d -s $session_name
tmux ls

tmux source ~/.tmux.conf

"$TPACK_DIR/bin/install_plugins"
"$TPACK_DIR/bin/update_plugins" all
"$TPACK_DIR/bin/clean_plugins"

tmux kill-session -t $session_name

exit 0
