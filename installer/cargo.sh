#!/usr/bin/env bash

set -eux -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh


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

set -x

# Maybe add to $PATH just to be safe
add_path "$HOME/.cargo/bin"

if [[ $(command -v cargo --version) ]]; then
    cargo install bat fd-find precious tidy-viewer
else
    echo "cargo not installed?"
fi

exit 0
