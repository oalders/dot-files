#!/usr/bin/env bash

set -e -u -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

install_for_linux() (
    sudo apt install -y libxcb-image0 libxkbcommon-x11-0 libwayland-client0 libwayland-egl1 libx11-xcb1
    version=$(is known os version)
    file=wezterm-nightly.${1}${version}.deb

    cd /tmp || exit 1
    url=https://github.com/wez/wezterm/releases/download/nightly/$file
    curl --location --output "$file" "$url"
    sudo dpkg -i "$file"
)

if is os name eq darwin; then
    if ! is there wezterm; then
        brew install --cask wezterm@nightly
    else
        command debounce 1 d brew upgrade --cask wezterm@nightly --no-quarantine --greedy-latest
    fi
elif is os name eq linux; then
    if ! is user sudoer; then
        echo "😭 $USER is not a sudoer"
        exit 0
    fi
    is there wezterm && is cli age wezterm lt 18 hours && exit
    if is os id eq ubuntu && is os version in 20.04,22.04,24.04; then
        install_for_linux Ubuntu
    elif is os id eq debian && is os version --major in 10,11,12; then
        install_for_linux Debian
    fi
fi
