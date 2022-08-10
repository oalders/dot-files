#!/usr/bin/env bash

set -eu

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# Pass a version arg if you want to install oh-my-posh on macOS"
# e.g. ./installer/oh-my-posh.sh v8.27.0"

set -x

CMD="ubi -p JanDeDobbeleer/oh-my-posh --in ~/local/bin"

if [[ ${1+x} ]]; then
    CMD="$CMD --tag $1"
fi

eval "$CMD"
