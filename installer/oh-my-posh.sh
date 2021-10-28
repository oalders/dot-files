#!/usr/bin/env bash

set -eu

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if [ "$IS_DARWIN" = true ]; then
    brew tap jandedobbeleer/oh-my-posh
    brew install oh-my-posh
fi
