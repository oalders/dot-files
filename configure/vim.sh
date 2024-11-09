#!/usr/bin/env bash

set -eu -o pipefail

PREFIX=~/dot-files

# shellcheck source=bash_functions.sh
source $PREFIX/bash_functions.sh

set -x

mkdir -p ~/.vim/rc/plug
mkdir -p ~/.vim
mkdir -p ~/.vimtmp

ln -sf "$LINK_FLAG" $PREFIX/vim/ftplugin ~/.vim/ftplugin

mkdir -p ~/.vim/after/syntax/perl
mkdir -p ~/.vim/after/plugin
ln -sf "$LINK_FLAG" $PREFIX/vim/after/syntax/perl/heredoc-sql.vim ~/.vim/after/syntax/perl/heredoc-sql.vim
ln -sf "$LINK_FLAG" $PREFIX/vim/after/syntax/gitcommit.vim ~/.vim/after/syntax/gitcommit.vim

if is there go; then
    go version
    unset GOPROXY
    debounce 18 h go install mvdan.cc/sh/v3/cmd/shfmt@latest
    debounce 18 h go install mvdan.cc/gofumpt@latest
else
    echo "Go not found. Not installing shfmt or gofumpt"
fi

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

rm -rf ~/.vim/Trashed-Bundles ~/.vim/bundle

# Not currently using vim as an editor
# rm -f ~/.vimrc
# ln -sf $PREFIX/vim/vim-plug-vimrc ~/.vimrc
# vim +'PlugInstall --sync' +qa

rm -f ~/.vimrc
ln -sf $PREFIX/vim/vimrc ~/.vimrc
ln -sf $PREFIX/vim/vim-plug-vimrc ~/.vim/vim-plug-vimrc

# Add abolish config *after* we know the plugin has been installed
ln -sf "$LINK_FLAG" $PREFIX/vim/after/plugin/abolish.vim ~/.vim/after/plugin/abolish.vim

# appimage isn't running on rpi
if is os id eq raspbian; then
    exit 0
fi

exit 0
