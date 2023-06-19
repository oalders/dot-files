#!/usr/bin/env bash

set -eu -o pipefail

if eval is os id eq raspbian; then
    exit 0
fi

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if eval is os name eq linux; then
    if [ "$IS_SUDOER" = true ]; then
        # https://askubuntu.com/questions/1290262/unable-to-install-bat-error-trying-to-overwrite-usr-crates2-json-which
        sudo apt-get install -o Dpkg::Options::="--force-overwrite" -y bat fd-find ripgrep
    fi
fi

exit 0

# Re-enable this when I need a Rust dev env

if eval is os name eq linux; then
    sudo apt-get -y install rustc cargo
fi

# Maybe add to $PATH just to be safe
add_path "$HOME/.cargo/bin"

if eval is there cargo; then
    cargo install cargo-edit
fi
if eval is there rustup; then
    rustup update
fi
