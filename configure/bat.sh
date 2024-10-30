#!/bin/bash

set -eux -o pipefail

if bat --list-themes | grep -q tokyonight; then
    # tokyonight themes already exist
    exit 0
fi

themes_dir="$(bat --config-dir)/themes"

mkdir -p "$themes_dir"
cd "$themes_dir"

# choose from day, night, moon or storm
flavour=moon

# Replace _moon in the lines below with _day, _night, or _storm if needed.
curl -O "https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_${flavour}.tmTheme"
bat cache --build
bat --list-themes | grep tokyo # should output "tokyonight_moon"
