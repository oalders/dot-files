#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

mkdir -p ~/.vim/rc/plug
mkdir -p ~/.vim

ln -sf $LINK_FLAG $SELF_PATH/../vim/ftplugin ~/.vim/ftplugin

if [ $IS_MM = true ]; then
    ln -sf ~/mm-dot-files/maxmind_local_vimrc ~/.local_vimrc
else
    ln -sf $SELF_PATH/../vim/vanilla_local_vim_plug_vimrc ~/.local_vim_plug_vimrc
fi

if [[ (-n "${GOPATH+set}" ) && ($(command -v go version)) ]]; then
    echo "Installing shfmt"
    go get -u mvdan.cc/sh/cmd/shfmt

    echo "Installing golangci-lint"
    go get -u github.com/golangci/golangci-lint/cmd/golangci-lint
else
    echo "Go not found. Not installing shfmt or golangci-lint"
fi

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

rm -rf ~/.vim/Trashed-Bundles ~/.vim/bundle

# The abolish plugin interferes with a fresh install
rm -f ~/.vim/after

rm -f ~/.vimrc
ln -sf $SELF_PATH/../vim/vim-plug-vimrc ~/.vimrc
vim +'PlugInstall --sync' +qa
rm ~/.vimrc

ln -sf $SELF_PATH/../vim/vimrc ~/.vimrc
ln -sf $SELF_PATH/../vim/vim-plug-vimrc ~/.vim/vim-plug-vimrc
ln -sf $LINK_FLAG $SELF_PATH/../vim/after ~/.vim/after

exit 0
