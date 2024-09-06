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
curl --location -O "https://github.com/Hammerspoon/Spoons/raw/master/Spoons/$file"
open $file
