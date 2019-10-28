#!/usr/bin/env bash

set -eu -o pipefail
source ~/dot-files/bash_functions.sh

if [[ $IS_SUDOER = false ]]; then
    exit 0
fi

if [[ $IS_DARWIN = false ]]; then
    sudo apt-get install -y cpanminus libnet-ssleay-perl nodejs pandoc tmux
    if [[ ! $HAS_GO ]]; then
        sudo apt-get install golang-go
    fi
fi

exit 0
