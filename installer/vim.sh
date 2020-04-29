#!/usr/bin/env bash

set -eu -o pipefail

if [ "$IS_DARWIN" = true ]; then
    exit 0
fi

sudo add-apt-repository ppa:jonathonf/vim
sudo apt update
sudo apt install vim

exit 0
