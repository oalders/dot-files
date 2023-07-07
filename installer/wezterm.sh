#!/usr/bin/env bash

set -eux

install_for_linux() {
    sudo apt install -y libxcb-image0 libxkbcommon-x11-0
    version=$(is known os version)
    local file="wezterm-nightly.${1}${version}.deb"

    pushd /tmp || exit 1
    local url="https://github.com/wez/wezterm/releases/download/nightly/$file"
    curl --location --output "$file" "$url"
    sudo dpkg -i "$file"
}

remove_wezterm() {
    rm -rf /Applications/WezTerm.app \
        /usr/local/bin/strip-ansi-escapes \
        /usr/local/bin/wezterm \
        /usr/local/bin/wezterm-gui \
        /usr/local/bin/wezterm-mux-server
}

if is os name eq darwin; then
    if is there wezterm; then
        brew upgrade homebrew/cask/wezterm
    else
        # remove_wezterm
        brew tap wez/wezterm
        brew install --cask wezterm --no-quarantine
    fi
elif is os name eq linux; then
    if is cli age wezterm lt 18 hours; then
        exit
    fi
    if [[ $IS_SUDOER == false ]]; then
        exit 0
    fi
    if is os id eq ubuntu && (is os version eq 20.04 || is os version eq 22.04); then
        install_for_linux Ubuntu
    elif is os id eq debian && (is os version eq 10 || is os version eq 11); then
        install_for_linux Debian
    fi
fi
