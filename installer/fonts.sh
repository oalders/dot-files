#!/usr/bin/env bash

set -eux -o pipefail

if is os name ne darwin; then
    exit 0
fi

git clone --branch 2015-12-04 --depth=1 https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd ..
rm -rf fonts

exit 0
