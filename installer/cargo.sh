#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [ "$IS_DARWIN" = false ]; then
    if [ "$IS_SUDOER" = true ]; then
        sudo apt-get -y install rustc cargo
    fi
fi

set -x

# Maybe add to $PATH just to be safe
add_path "$HOME/.cargo/bin"

if [[ $(command -v cargo --version) ]]; then
    cargo install -q precious
    cargo install -q bats
else
    echo "cargo not installed?"
fi

exit 0
