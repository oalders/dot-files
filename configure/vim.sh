#!/usr/bin/env bash

set -eux -o pipefail

PREFIX=~/dot-files

# shellcheck source=bash_functions.sh
source $PREFIX/bash_functions.sh

mkdir -p ~/.vim/rc/plug
mkdir -p ~/.vim
mkdir -p ~/.vimtmp

ln -sf "$LINK_FLAG" $PREFIX/vim/ftplugin ~/.vim/ftplugin

mkdir -p ~/.vim/after/syntax/perl
mkdir -p ~/.vim/after/plugin
ln -sf "$LINK_FLAG" $PREFIX/vim/after/syntax/perl/heredoc-sql.vim ~/.vim/after/syntax/perl/heredoc-sql.vim
ln -sf "$LINK_FLAG" $PREFIX/vim/after/syntax/gitcommit.vim ~/.vim/after/syntax/gitcommit.vim

if [[ $HAS_GO = true ]]; then
    go version
    echo "Installing shfmt"
    go get -u mvdan.cc/sh/v3/cmd/shfmt
    go get mvdan.cc/gofumpt

    # https://github.com/golangci/golangci-lint#binary
    echo "Installing golangci-lint"
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$(go env GOPATH)"/bin v1.40.1

    GO111MODULE=on go get -u golang.org/x/tools/gopls@v0.7.0-pre.3
    GO111MODULE=on go get mvdan.cc/gofumpt/gofumports
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

if [ "$IS_MM" = true ]; then
    ln -sf ~/local-dot-files/maxmind_local_vimrc ~/.local_vimrc

    mkdir -p  ~/.vim/after/ftplugin
    ln -sf ~/local-dot-files/vim/after/ftplugin/perl.vim ~/.vim/after/ftplugin/perl.vim
fi

# Add abolish config *after* we know the plugin has been installed
ln -sf "$LINK_FLAG" $PREFIX/vim/after/plugin/abolish.vim ~/.vim/after/plugin/abolish.vim
exit 0
