#!/bin/bash

set -eux
cd /tmp || exit

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [ "$IS_DARWIN" = true ]; then
    DIR=nvim-osx64
    FILE=nvim-macos.tar.gz
    rm -rf $DIR
else
    FILE=nvim.appimage
fi

URL=https://github.com/neovim/neovim/releases/download/nightly/$FILE

rm -rf $FILE
curl -LO $URL

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
