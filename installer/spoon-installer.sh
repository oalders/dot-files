#!/usr/bin/env bash

set -eux

if [ -d "./hammerspoon/Spoons" ] && [ "$(ls -A ./hammerspoon/Spoons)" ]; then
    echo "Spoons have already been installed"
    exit 0
fi

cd /tmp || exit 1

file=SpoonInstall.spoon.zip

rm -f $file
rm -rf SpoonInstall.spoon
# Pin to a specific commit to avoid pulling unexpected changes
curl --location -O "https://github.com/Hammerspoon/Spoons/raw/5c20bcecc380acff5f0f5df7a718c5679aaaf62a/Spoons/$file"
open $file
