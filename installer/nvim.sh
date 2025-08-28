#!/usr/bin/env bash

# May need to sudo apt install libfuse2 on Ubuntu >= 22.04
# https://docs.appimage.org/user-guide/troubleshooting/fuse.html

set -eux

if is there nvim && is cli age nvim lt 18 hours; then
    exit
fi

if is os id eq raspbian; then
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

if is os id eq almalinux; then
    URL=https://github.com/neovim/neovim-releases/releases/download/v0.10.2/
fi

if is os name eq darwin; then
    if is arch eq arm64; then
        dir=nvim-macos-arm64
    else
        dir=nvim-macos-x86_64
    fi
    download_file="$dir.tar.gz"
    rm -rf $dir
else
    download_file=nvim-linux-x86_64.appimage
fi

curl -LO --fail -z $download_file "$URL$download_file"

if is os name eq darwin; then
    tar xzvf $download_file
    dest="$HOME/local/bin/nvim-macos"
    rm -rf "$dest"
    mv "$dir" "$dest"
    rm -f "$HOME/local/bin/nvim"
    add_path "$HOME/local/bin/nvim-macos/bin"
else
    chmod u+x $download_file
    mv $download_file "$HOME/local/bin/nvim"
fi

echo "done nvim install"

if is var IS_GITHUB true; then
    ldd --version
else
    # nvim --headless "+Lazy! sync" +qa
    nvim --headless "+MasonToolsUpdateSync" +qa
fi

exit 0
