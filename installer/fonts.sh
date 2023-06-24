#!/usr/bin/env bash

set -eux -o pipefail

if is os name ne darwin; then
    exit 0
fi

git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

exit 0
