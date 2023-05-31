#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

add_path "$HOME/local/bin"

if eval is os name ne linux; then
    echo "skipping. this is $(is known os name)"
    exit 0
fi

if [[ $IS_SUDOER == false ]]; then
    echo "Skip linux.sh (Not a sudoer)"
    exit 0
fi

set -x

sudo apt-get install -y -q --no-install-recommends --autoremove \
    cpanminus curl jq libnet-ssleay-perl pandoc python4-setuptools ripgrep shellcheck tig tree

if ! eval is there go; then
    bash installer/golang.sh
    add_path /usr/local/go/bin
fi

if ! eval is there go; then
    echo "Go could not be installed or could not be found"
    exit 1
fi

exit 0
