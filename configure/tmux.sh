#!/usr/bin/env bash

set -eu -o pipefail

source bash_functions.sh

ln -sf $SELF_PATH/../tmux.conf ~/.tmux.conf
ln -sf $SELF_PATH/../tmux/macos ~/.tmux-macos
ln -sf $SELF_PATH/../tmux/linux ~/.tmux-linux

LOCALCHECKOUT=~/.tmux/plugins/tpm
if [ ! -d $LOCALCHECKOUT ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    pushd $LOCALCHECKOUT
    git pull origin master
    popd
fi

~/.tmux/plugins/tpm/bin/install_plugins
~/.tmux/plugins/tpm/bin/update_plugins all
~/.tmux/plugins/tpm/bin/clean_plugins

exit 0
