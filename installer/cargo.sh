#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if eval is os name eq linux; then
    if [ "$IS_SUDOER" = true ]; then
        if [[ -n ${PREFER_PKGS+set} ]]; then
            # https://askubuntu.com/questions/1290262/unable-to-install-bat-error-trying-to-overwrite-usr-crates2-json-which
            sudo apt-get install -o Dpkg::Options::="--force-overwrite" -y bat fd-find ripgrep
            exit 0
        fi
        sudo apt-get -y install rustc cargo
    fi
fi

exit 0

# Maybe add to $PATH just to be safe
add_path "$HOME/.cargo/bin"

if eval is there cargo; then
    cargo install cargo-edit
fi
if eval is there rustup; then
    rustup update
fi
