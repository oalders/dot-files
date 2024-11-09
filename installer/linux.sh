#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

add_path "$HOME/local/bin"

if is os name ne linux; then
    echo "skipping. this is $(is known os name)"
    exit 0
fi

if [[ $IS_SUDOER == false ]]; then
    echo "Skip linux.sh (Not a sudoer)"
    exit 0
fi

set -x

if is os id eq almalinux; then
    sudo dnf install -y -q \
        chafa \
        cpanminus \
        curl \
        fd-find \
        jq \
        npm \
        pandoc \
        python3-setuptools \
        ripgrep \
        tig \
        tree
    exit 0
else

    sudo apt-get install -y -q --no-install-recommends --autoremove \
        build-essential \
        chafa \
        cpanminus \
        curl \
        jq \
        libnet-ssleay-perl \
        pandoc \
        python3-setuptools \
        ripgrep \
        shellcheck \
        tig \
        tree
fi

if ! is there go; then
    bash installer/golang.sh
    add_path /usr/local/go/bin
    add_path "$HOME"/local/bin/go/bin
fi

if ! is there go; then
    echo "Go could not be installed or could not be found"
    exit 1
fi

exit 0
