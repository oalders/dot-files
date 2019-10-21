#!/usr/bin/env bash

set -eu -o pipefail

source bash_functions.sh

pushd ~/dot-files

ln -sf ~/dot-files/tmux.conf ~/.tmux.conf
exit
ln -sf ~/dot-files/tmux/macos ~/.tmux-macos
ln -sf ~/dot-files/tmux/linux ~/.tmux-linux

if [[! $IS_DARWIN ]]; then
    sudo apt-get install tree
fi

LOCALCHECKOUT=~/.tmux/plugins/tpm
if [ ! -d $LOCALCHECKOUT ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    pushd $LOCALCHECKOUT
    git pull origin master
    popd
fi

tree ~/.tmux

tmux source ~/.tmux.conf

~/.tmux/plugins/tpm/bin/install_plugins
~/.tmux/plugins/tpm/bin/update_plugins all
~/.tmux/plugins/tpm/bin/clean_plugins

popd

exit 0
