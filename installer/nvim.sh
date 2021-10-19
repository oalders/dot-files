#!/bin/bash

set -eux
cd /tmp || exit

if [ "$IS_DARWIN" = true ]; then
    DIR=nvim-osx64
    FILE=nvim-macos.tar.gz
    rm -f $FILE
    rm -rf $DIR
    curl -LO https://github.com/neovim/neovim/releases/download/nightly/$FILE
    tar xzvf $FILE
    rm -rf ~/local/$DIR
    mv  $DIR ~/local/
    vim +'PlugInstall --sync' +qa
    echo "done nvim install"
    exit 0
fi

FILE=nvim.appimage

rm -f $FILE
curl -LO https://github.com/neovim/neovim/releases/latest/download/$FILE
chmod u+x $FILE
mv $FILE ~/local/bin/nvim
