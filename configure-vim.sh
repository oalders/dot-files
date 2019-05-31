#!/usr/bin/env bash

set -eu -o pipefail

SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

LINK_FLAG=""

# https://stackoverflow.com/a/17072017/406224
if [ "$(uname)" == "Darwin" ]; then
    echo "This is Darwin"
    LINK_FLAG="-hF"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "This is Linux"
    LINK_FLAG="-T"
fi

echo $SELF_PATH

mkdir -p ~/.vim/rc/plug

IS_MM=false
if [ -e /usr/local/bin/mm-perl ]; then
    IS_MM=true
fi

mkdir -p ~/.vim
ln -sf $LINK_FLAG $SELF_PATH/vim/ftplugin ~/.vim/ftplugin

if [ $IS_MM = true ]; then
    ln -sf ~/mm-dot-files/maxmind_local_vimrc ~/.local_vimrc
else
    ln -sf $SELF_PATH/vim/vanilla_local_vimrc ~/.local_vimrc
fi

if [ -n "${GOPATH+set}" ] && [$(type "go" >/dev/null) ]; then
    echo "Installing shfmt"
    go get -u mvdan.cc/sh/cmd/shfmt

    echo "Installing golangci-lint"
    go get -u github.com/golangci/golangci-lint/cmd/golangci-lint
fi

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

rm -rf ~/.vim/Trashed-Bundles ~/.vim/bundle

# The abolish plugin interferes with a fresh install
rm -f ~/.vim/after

rm -f ~/.vimrc
ln -sf $SELF_PATH/vim/vim-plug-vimrc ~/.vimrc
vim +'PlugInstall --sync' +qa
rm ~/.vimrc

ln -sf $SELF_PATH/vim/vimrc ~/.vimrc
ln -sf $SELF_PATH/vim/vim-plug-vimrc ~/.vim/vim-plug-vimrc
ln -sf $LINK_FLAG $SELF_PATH/vim/after ~/.vim/after
