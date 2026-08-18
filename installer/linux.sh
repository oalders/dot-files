#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

add_path "$HOME/local/bin"

if is os name ne linux; then
    echo "skipping. this is $(is known os name)"
    exit 0
fi

if [[ $IS_SUDOER == false ]]; then
    echo "Skip linux.sh (Not a sudoer)"
    exit 0
fi

set -x

if ! is there apt; then
    sudo dnf install -y -q \
        chafa \
        cpanminus \
        curl \
        expat-devel \
        fd-find \
        jq \
        npm \
        pandoc \
        python3-setuptools \
        ripgrep \
        tig \
        tree
    exit 0
else

    debounce 12 h sudo apt-get update -q

    packages=(
        build-essential
        chafa
        cpanminus
        curl
        jq
        libexpat1-dev
        libnet-ssleay-perl
        libsecret-tools
        locate
        luarocks
        pandoc
        pipx
        python3-pip
        python3-setuptools
        ripgrep
        shellcheck
        tig
        tree
        trurl
    )

    # gnome-keyring pulls in a GTK4/GCR desktop stack (libgtk-4-1,
    # libgcr-ui-3-1, pinentry-gnome3, ...) that's only useful for an
    # interactive desktop session storing git credentials. CI never launches
    # the keyring daemon, so skip it there to avoid downloading packages
    # nothing exercises. IS_GITHUB comes from bash_functions.sh (sourced
    # above), the repo's existing "are we in CI" signal.
    if [[ $IS_GITHUB == false ]]; then
        packages+=(gnome-keyring)
    fi

    sudo apt-get install -y -q --no-install-recommends --autoremove "${packages[@]}"
fi

if ! is there go; then
    bash installer/golang.sh
    add_path /usr/local/go/bin
    add_path "$HOME"/local/bin/go/bin
fi

if ! is there go; then
    echo "Go could not be installed or could not be found"
    exit 1
fi

exit 0
