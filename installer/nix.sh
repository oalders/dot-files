#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

if is os name ne linux; then
    echo "skipping. this is $(is known os name)"
    exit 0
fi

if [[ $IS_SUDOER == false ]]; then
    echo "Skip nix.sh (Not a sudoer)"
    exit 0
fi

# The nix-users group gates access to the multi-user Nix daemon socket.
if ! getent group nix-users >/dev/null; then
    echo "Skip nix.sh (no 'nix-users' group; is Nix installed?)"
    exit 0
fi

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx nix-users; then
    sudo usermod -aG nix-users "$USER"
    echo "Added $USER to 'nix-users' group. Log out and back in for it to take effect."
fi

exit 0
