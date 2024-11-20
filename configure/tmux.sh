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

LOCALCHECKOUT=~/.tmux/plugins/tpm
if [ ! -d $LOCALCHECKOUT ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    (cd $LOCALCHECKOUT && git pull origin master)
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

~/.tmux/plugins/tpm/bin/install_plugins
~/.tmux/plugins/tpm/bin/update_plugins all
~/.tmux/plugins/tpm/bin/clean_plugins

tmux kill-session -t $session_name

exit 0
