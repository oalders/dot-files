#!/usr/bin/env bash

# May need to sudo apt install libfuse2 on Ubuntu >= 22.04
# https://docs.appimage.org/user-guide/troubleshooting/fuse.html

set -eu
cd /tmp || exit

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

URL=https://github.com/neovim/neovim/releases/download/nightly/

if [ "$IS_DARWIN" = true ]; then
    # Enable if nightly tarballs go missing again
    brew install --head neovim
    rm -f "$HOME/local/bin/nvim"
    exit 0

    DIR=nvim-osx64
    FILE=nvim-macos.tar.gz
    rm -rf $DIR
else
    FILE=nvim.appimage
fi

curl -LO --fail -z $FILE "$URL$FILE"

if [ "$IS_DARWIN" = true ]; then
    tar xzvf $FILE
else
    chmod u+x $FILE
fi

mv $FILE "$HOME/local/bin/nvim"

echo "done nvim install"
exit 0
