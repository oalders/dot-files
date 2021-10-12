#!/usr/bin/env bash

set -eux -o pipefail

if [ "$IS_DARWIN" = false ]; then
    exit 0
fi

brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font

git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

exit 0
