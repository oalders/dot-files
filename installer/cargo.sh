#!/usr/bin/env bash

set -eux -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh


if [ "$IS_DARWIN" = false ]; then
    if [ "$IS_SUDOER" = true ]; then
        if [[ (-n "${PREFER_PKGS+set}") ]]; then
            sudo apt-get install -y bats fd-find ripgrep
            exit 0
        fi
        sudo apt-get -y install rustc cargo
    fi
fi

set -x

# Maybe add to $PATH just to be safe
add_path "$HOME/.cargo/bin"

if [[ $(command -v cargo --version) ]]; then
    cargo install bats fd-find precious
else
    echo "cargo not installed?"
fi

exit 0
