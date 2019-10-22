#!/usr/bin/env bash

set -eu -o pipefail

source bash_functions.sh

pushd ~/dot-files

ln -sf tmux.conf ~/.tmux.conf
ln -sf tmux/macos ~/.tmux-macos
ln -sf tmux/linux ~/.tmux-linux

sudo apt-get install tree

LOCALCHECKOUT=~/.tmux/plugins/tpm
if [ ! -d $LOCALCHECKOUT ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    pushd $LOCALCHECKOUT
    git pull origin master
    popd
fi

tree ~/.tmux

~/.tmux/plugins/tpm/bin/install_plugins
~/.tmux/plugins/tpm/bin/update_plugins all
~/.tmux/plugins/tpm/bin/clean_plugins

popd

exit 0
