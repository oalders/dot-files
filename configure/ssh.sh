#!/usr/bin/env bash

set -eu -o pipefail

PREFIX=~/dot-files
source $PREFIX/bash_functions.sh

mkdir -p ~/.ssh/sockets

ln -sf $PREFIX/ssh/rc ~/.ssh/rc

if [ $IS_DARWIN = true ]; then
    ln -sf $PREFIX/ssh/config ~/.ssh/config
    mkdir -p ~/.ssh/config.d/
    if [[ -d ~/local-dot-files/ssh/config.d ]]; then
        pushd ~/.ssh/config.d/
        ln -sf ~/local-dot-files/ssh/config.d/* .
        popd
    fi
else
    rm -f ~/.ssh/config
    ln -sf $PREFIX/ssh/no-include-config ~/.ssh/config
fi

exit 0
