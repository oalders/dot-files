#!/bin/bash

set -eux
cd /tmp || exit

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [ "$IS_DARWIN" = true ]; then
    # Nightly tarballs seem to be missing right now
    brew install --head neovim
    exit 0

    DIR=nvim-osx64
    FILE=nvim-macos.tar.gz
    URL=https://github.com/neovim/neovim/releases/download/nightly/
    rm -rf $DIR
else
    FILE=nvim.appimage
    URL=https://github.com/neovim/neovim/releases/latest/download/
fi

curl -LO --fail -z $FILE "$URL$FILE"

if [ "$IS_DARWIN" = true ]; then
    tar xzvf $FILE
    rm -rf ~/local/$DIR
    mv $DIR ~/local/
else
    chmod u+x $FILE
    mv $FILE ~/local/bin/nvim
fi

vim +'PlugInstall --sync' +qa
echo "done nvim install"
exit 0
