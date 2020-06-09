#!/usr/bin/env bash

set -eu -o pipefail

PREFIX=~/dot-files

# shellcheck source=bash_functions.sh
source $PREFIX/bash_functions.sh

mkdir -p ~/.vim/rc/plug
mkdir -p ~/.vim
mkdir -p ~/.vimtmp

ln -sf "$LINK_FLAG" $PREFIX/vim/ftplugin ~/.vim/ftplugin

if [ "$IS_MM" = true ]; then
    ln -sf ~/local-dot-files/maxmind_local_vimrc ~/.local_vimrc

    mkdir -p  ~/.vim/after/ftplugin
    ln -sf ~/local-dot-files/vim/after/ftplugin/perl.vim ~/.vim/after/ftplugin/perl.vim
fi

if [[ $HAS_GO = true ]]; then
    echo "Installing shfmt"
    go get -u mvdan.cc/sh/v3/cmd/shfmt

    # https://github.com/golangci/golangci-lint#binary
    echo "Installing golangci-lint"
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$(go env GOPATH)"/bin v1.26.0

    go get -u golang.org/x/tools/gopls@master
else
    echo "Go not found. Not installing shfmt or golangci-lint"
fi

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

rm -rf ~/.vim/Trashed-Bundles ~/.vim/bundle

rm -f ~/.vimrc
ln -sf $PREFIX/vim/vim-plug-vimrc ~/.vimrc
vim +'PlugInstall --sync' +qa
rm ~/.vimrc

ln -sf $PREFIX/vim/vimrc ~/.vimrc
ln -sf $PREFIX/vim/vim-plug-vimrc ~/.vim/vim-plug-vimrc

mkdir -p ~/.vim/after/plugin
ln -sf "$LINK_FLAG" $PREFIX/vim/after ~/.vim/after

exit 0
