#!/usr/bin/env bash

set -eu

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if [[ $IS_DARWIN = false ]] && [[ $IS_SUDOER = true ]]; then
    sudo apt-get install -y libevent-dev libncurses5-dev
    RELEASE=tmux-3.3a
    ARCHIVE="$RELEASE.tar.gz"
    cd /tmp || exit
    rm -rf $ARCHIVE $RELEASE
    curl --fail --location "https://github.com/tmux/tmux/releases/download/3.3a/$ARCHIVE" -o $ARCHIVE
    tar xzvf $ARCHIVE
    cd $RELEASE
    ./configure && make
    sudo make install

    # Also remove any remaining server sockets, or we may be unable to restart tmux.
    # https://github.com/tmux/tmux/issues/2376#issuecomment-695195592
    rm -rf /tmp/tmux*
fi
