#!/usr/bin/env bash

set -eu

INSTALL_DIR="$HOME/local/bin"
# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
add_path "$INSTALL_DIR"

# Pass a version arg if you want to install oh-my-posh on macOS"
# e.g. ./installer/oh-my-posh.sh v8.27.0"

set -x

CMD="ubi -p JanDeDobbeleer/oh-my-posh --in $INSTALL_DIR"

if [[ ${1+x} ]]; then
    CMD="$CMD --tag $1"
fi

eval "$CMD"
