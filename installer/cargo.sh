#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if [ "$IS_DARWIN" = false ]; then
    if [ "$IS_SUDOER" = true ]; then
        if [[ (-n "${PREFER_PKGS+set}") ]]; then
            # https://askubuntu.com/questions/1290262/unable-to-install-bat-error-trying-to-overwrite-usr-crates2-json-which
            sudo apt-get install -o Dpkg::Options::="--force-overwrite" -y bat fd-find ripgrep
            exit 0
        fi
        sudo apt-get -y install rustc cargo
    fi
fi

set +x

# Maybe add to $PATH just to be safe
add_path "$HOME/.cargo/bin"

set -x

if [[ $(command -v cargo --version) ]]; then
    if [[ "$IS_DARWIN" = true ]]; then
        rustup update
        cargo install cargo-edit
    else
        cargo install fd-find
    fi
else
    echo "cargo not installed?"
fi

exit 0
