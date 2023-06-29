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

$CMD

if [[ $IS_GITHUB == true ]]; then
    exit 0
fi

if ! is there fc-list; then
    sudo apt-get install -y fontconfig
fi

if ! fc-list : family | grep "JetBrainsMono Nerd Font" &>/dev/null; then
    oh-my-posh font install JetBrainsMono
fi
