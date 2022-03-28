#!/usr/bin/env bash

set -eu

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if [ "$IS_DARWIN" = false ]; then
    FILE=oh-my-posh
    cd /tmp || exit
    curl --fail --location https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -o $FILE
    chmod +x $FILE
    mv $FILE ~/local/bin/
fi
