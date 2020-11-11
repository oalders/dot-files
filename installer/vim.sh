#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [ "$IS_DARWIN" = true ]; then
    exit 0
fi

if [[ $(which vim) ]]; then
    exit 0
fi

if [[ $IS_SUDOER = false ]]; then
    exit 0
fi

set -x

# maybe install add-apt-repository
sudo apt-get install -y --no-install-recommends software-properties-common

if [[ $USER != "pi" ]]; then
  sudo add-apt-repository -y ppa:jonathonf/vim
fi

sudo apt update
sudo apt install -y --no-install-recommends vim

exit 0
