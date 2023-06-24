#!/usr/bin/env bash

set -eux

remove_wezterm() {
    rm -rf /Applications/WezTerm.app \
        /usr/local/bin/strip-ansi-escapes \
        /usr/local/bin/wezterm \
        /usr/local/bin/wezterm-gui \
        /usr/local/bin/wezterm-mux-server
}

if is there wezterm; then
    brew upgrade homebrew/cask/wezterm
else
    # remove_wezterm
    brew tap wez/wezterm
    brew install --cask wezterm --no-quarantine
fi
