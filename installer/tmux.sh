#!/usr/bin/env bash

set -eu

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x
target_version=3.4

is cli version tmux eq $target_version && exit
is os name eq darwin && exit

if [[ $IS_SUDOER == true ]]; then
    sudo apt-get install -y bison libevent-dev libncurses5-dev
fi

release="tmux-$target_version"
archive="$release.tar.gz"
cd /tmp || exit
rm -rf $archive $release
curl --fail --location "https://github.com/tmux/tmux/releases/download/$target_version/$archive" -o $archive
tar xzvf $archive
cd $release
./configure --prefix ~/local
make install

# Also remove any remaining server sockets, or we may be unable to restart tmux.
# https://github.com/tmux/tmux/issues/2376#issuecomment-695195592
rm -rf /tmp/tmux*
