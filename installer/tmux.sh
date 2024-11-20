#!/usr/bin/env bash

set -eu

if is os id eq almalinux; then
    exit
fi

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x
target_version=3.5a

is cli version tmux eq $target_version && exit
is os name eq darwin && exit

if [[ $IS_SUDOER == true ]]; then
    if is os id eq almalinux; then
        sudo dnf install -y bison
    else
        sudo apt-get install -y bison libevent-dev libncurses5-dev
    fi
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
