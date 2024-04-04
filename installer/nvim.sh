#!/usr/bin/env bash

# May need to sudo apt install libfuse2 on Ubuntu >= 22.04
# https://docs.appimage.org/user-guide/troubleshooting/fuse.html

set -eux

if is cli age nvim lt 18 hours; then
    exit
fi

cd /tmp || exit

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

    dir=nvim-osx64
    download_file=nvim-macos.tar.gz
    rm -rf $dir
elif is os id eq raspbian; then
    exit 0
    # Won't run on buster
    # sudo apt install snapd
    # sudo snap install nvim --classic
else
    download_file=nvim.appimage
fi

curl -LO --fail -z $download_file "$URL$download_file"

if is os name eq darwin; then
    tar xzvf $download_file
    dest="$HOME/local/bin/nvim-macos"
    rm -rf "$dest"
    mv nvim-macos "$dest"
    rm -f "$HOME/local/bin/nvim"
    add_path "$HOME/local/bin/nvim-macos/bin"
else
    chmod u+x $download_file
    mv $download_file "$HOME/local/bin/nvim"
fi

echo "done nvim install"
exit 0
