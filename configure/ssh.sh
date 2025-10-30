#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

PREFIX=~/dot-files

mkdir -p ~/.ssh/sockets

ln -sf $PREFIX/ssh/rc ~/.ssh/rc

if [[ -d ~/local-dot-files ]]; then
    ln -sf $PREFIX/ssh/config ~/.ssh/config
    mkdir -p ~/.ssh/config.d/
    if [[ -d ~/local-dot-files/ssh/config.d ]]; then
        (cd ~/.ssh/config.d/ && ln -sf ~/local-dot-files/ssh/config.d/* .)
    fi
else
    rm -f ~/.ssh/config
    ln -sf $PREFIX/ssh/no-include-config ~/.ssh/config
fi

exit 0
