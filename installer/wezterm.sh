#!/bin/bash

set -eux

if [[ $(which wezterm) ]]; then
    brew upgrade homebrew/cask/wezterm
else
    brew tap wez/wezterm
    brew install --cask wezterm --no-quarantine
fi
