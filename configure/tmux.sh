#!/usr/bin/env bash

set -eu -o pipefail

PREFIX=~/dot-files

source $PREFIX/bash_functions.sh

tmux -V

ln -sf $PREFIX/tmux.conf ~/.tmux.conf

if [[ $IS_DARWIN == true ]]; then
    echo "Symlinking MacOS source file"
    ln -sf $PREFIX/tmux/macos ~/.tmux-this-os
else
    ln -sf $PREFIX/tmux/linux ~/.tmux-this-os
fi

LOCALCHECKOUT=~/.tmux/plugins/tpm
if [ ! -d $LOCALCHECKOUT ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    pushd $LOCALCHECKOUT
    git pull origin master
    popd
fi

# tmux needs to be running in order to source a config file etc
if [[ $IS_GITHUB == true ]]; then
    tmux new-session -d -s CI
    tmux ls
fi

tmux source ~/.tmux.conf

~/.tmux/plugins/tpm/bin/install_plugins
~/.tmux/plugins/tpm/bin/update_plugins all
~/.tmux/plugins/tpm/bin/clean_plugins

exit 0
