#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

mkdir -p ~/.ssh/sockets
ln -sf $SELF_PATH/ssh/rc ~/.ssh/rc

if [ $IS_DARWIN = true ]; then
    ln -sf $SELF_PATH/ssh/config ~/.ssh/config
    if [[ -d ~/local-dot-files/ssh/config.d ]]; then
        pushd ~/.ssh/config.d/
        ln -s ~/local-dot-files/ssh/config.d/* .
        popd
    fi
else
    rm -f ~/.ssh/config
    ln -sf $SELF_PATH/ssh/no-include-config ~/.ssh/config
fi
