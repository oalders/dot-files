#!/usr/bin/env bash

set -eu -o pipefail

PREFIX=~/dot-files

# shellcheck source=bash_functions.sh
source $PREFIX/bash_functions.sh
add_path "$HOME/local/bin"

set -x

if ! is there tmux || is cli version tmux lt 3.2; then
    ./installer/tmux.sh
fi

ln -sf $PREFIX/tmux.conf ~/.tmux.conf

if is os name eq darwin; then
    echo "Symlinking MacOS source file"
    ln -sf $PREFIX/tmux/macos ~/.tmux-this-os
else
    ln -sf $PREFIX/tmux/linux ~/.tmux-this-os
fi

LOCALCHECKOUT=~/.tmux/plugins/tpm
if [ ! -d $LOCALCHECKOUT ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    (cd $LOCALCHECKOUT && git pull origin master)
fi

# tmux needs to be running in order to source a config file etc
# Also clean up an old CI sessions
tmux kill-session -t CI || true
tmux new-session -d -s CI
tmux ls

tmux source ~/.tmux.conf

~/.tmux/plugins/tpm/bin/install_plugins
~/.tmux/plugins/tpm/bin/update_plugins all
~/.tmux/plugins/tpm/bin/clean_plugins

tmux kill-session -t CI

exit 0
