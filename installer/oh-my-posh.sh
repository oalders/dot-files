#!/usr/bin/env bash

set -eu

install_dir="$HOME/local/bin"
# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
add_path "$install_dir"

# Pass a version arg if you want to install oh-my-posh on macOS"
# e.g. ./installer/oh-my-posh.sh v8.27.0"

set -x

cmd="ubi -p JanDeDobbeleer/oh-my-posh --in $install_dir"

if [[ ${1+x} ]]; then
    cmd="$cmd --tag $1"
fi

$cmd

if [[ $IS_GITHUB == true ]]; then
    exit 0
fi

if ! is there fc-list; then
    sudo apt-get install -y fontconfig
fi

if ! fc-list : family | grep "JetBrainsMono Nerd Font" &>/dev/null; then
    oh-my-posh font install JetBrainsMono
fi
