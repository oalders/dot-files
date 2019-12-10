#!/usr/bin/env bash

set -eu -o pipefail

if [ $IS_DARWIN = false ]; then
    exit 0
fi

source ~/dot-files/bash_functions.sh

# Maybe add to $PATH just to be safe
add_path "$HOME/.cargo/bin"

if [[ $(command -v precious --version) ]]; then
    echo "precious already installed"
else
    cargo install -q precious
fi

exit 0
