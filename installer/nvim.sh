#!/bin/bash

set -eu
cd /tmp || exit

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

URL=https://github.com/neovim/neovim/releases/download/nightly/

if [ "$IS_DARWIN" = true ]; then
    # Enable if nightly tarballs go missing again
    #brew install --head neovim
    #exit 0

    DIR=nvim-osx64
    FILE=nvim-macos.tar.gz
    rm -rf $DIR
else
    FILE=nvim.appimage
fi

curl -LO --fail -z $FILE "$URL$FILE"

if [ "$IS_DARWIN" = true ]; then
    tar xzvf $FILE
    rm -rf ~/local/$DIR
    mv $DIR ~/local/
else
    chmod u+x $FILE
    mv $FILE "$HOME/local/bin/nvim"
    add_path "$HOME/local/bin"
    echo_path
fi

if [[ $IS_GITHUB = false ]]; then
    nvim +'PlugInstall --sync' +qa
fi

echo "done nvim install"
exit 0
