#!/usr/bin/env bash

set -eux

# ~/.hammerspoon is symlinked to this repo's hammerspoon dir.
spoons_dir="$HOME/.hammerspoon/Spoons"

if [ -d "$spoons_dir/SpoonInstall.spoon" ]; then
    echo "SpoonInstall has already been installed"
    exit 0
fi

mkdir -p "$spoons_dir"

cd /tmp || exit 1

file=SpoonInstall.spoon.zip

rm -f $file
rm -rf SpoonInstall.spoon
# Pin to a specific commit to avoid pulling unexpected changes
curl --location -O "https://github.com/Hammerspoon/Spoons/raw/5c20bcecc380acff5f0f5df7a718c5679aaaf62a/Spoons/$file"
# `open`-ing the zip only unzips it; it never installs the Spoon. Unzip it
# straight into the Spoons dir so Hammerspoon can load it.
unzip -o $file -d "$spoons_dir"
