#!/usr/bin/env bash

# May need to sudo apt install libfuse2 on Ubuntu >= 22.04
# https://docs.appimage.org/user-guide/troubleshooting/fuse.html

set -eu

if is cli age nvim lt 18 hours; then
    exit
fi

pushd /tmp || exit


if (is os id eq ubuntu && is os version gte 22.04) || (is os id eq debian); then
    sudo apt install libfuse2
fi

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

URL=https://github.com/neovim/neovim/releases/download/nightly/

if is os name eq darwin; then
    # Enable if nightly tarballs go missing again
    # brew install --head neovim
    # rm -f "$HOME/local/bin/nvim"
    # exit 0

    DIR=nvim-osx64
    FILE=nvim-macos.tar.gz
    rm -rf $DIR
elif is os id eq raspbian; then
    exit 0
    # Won't run on buster
    # sudo apt install snapd
    # sudo snap install nvim --classic
else
    FILE=nvim.appimage
fi

curl -LO --fail -z $FILE "$URL$FILE"

if is os name eq darwin; then
    tar xzvf $FILE
else
    chmod u+x $FILE
fi

mv $FILE "$HOME/local/bin/nvim"

popd
./installer/tree-sitter-perl.sh

echo "done nvim install"
exit 0
