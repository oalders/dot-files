#!/usr/bin/env bash

set -eux

cd /tmp || exit 1

FILE=SpoonInstall.spoon.zip

rm -f $FILE
rm -rf SpoonInstall.spoon
curl --location -O "https://github.com/Hammerspoon/Spoons/raw/master/Spoons/$FILE"
open $FILE
