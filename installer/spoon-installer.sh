#!/bin/bash

set -eux

cd /tmp || exit 1

FILE=SpoonInstall.spoon.zip

rm $FILE
rm -rf SpoonInstall.spoon
curl --location -O "https://github.com/Hammerspoon/Spoons/raw/master/Spoons/$FILE"
open $FILE
