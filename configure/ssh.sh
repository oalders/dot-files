#!/usr/bin/env bash

set -eu -o pipefail

pushd ~/dot-files
source bash_functions.sh

mkdir -p ~/.ssh/sockets

ln -sf ssh/rc ~/.ssh/rc

if [ $IS_DARWIN = true ]; then
    ln -sf ssh/config ~/.ssh/config
    mkdir -p ~/.ssh/config.d/
    if [[ -d ~/local-dot-files/ssh/config.d ]]; then
        pushd ~/.ssh/config.d/
        ln -sf ~/local-dot-files/ssh/config.d/* .
        popd
    fi
else
    rm -f ~/.ssh/config
    ln -sf ssh/no-include-config ~/.ssh/config
fi

popd
exit 0
