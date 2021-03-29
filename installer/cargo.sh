#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [ "$IS_DARWIN" = false ]; then
    if [ "$IS_SUDOER" = true ]; then
        sudo apt-get install rustc cargo
        cargo install bats
    fi
fi

set -x

# Maybe add to $PATH just to be safe
add_path "$HOME/.cargo/bin"

if [[ $(command -v precious --version) ]]; then
    echo "precious already installed"
else
    cargo install -q precious
fi

exit 0
