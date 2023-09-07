#!/usr/bin/env bash

set -eux

cd /tmp || exit 1

file=SpoonInstall.spoon.zip

rm -f $file
rm -rf SpoonInstall.spoon
curl --location -O "https://github.com/Hammerspoon/Spoons/raw/master/Spoons/$file"
open $file
