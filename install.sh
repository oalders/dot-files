#!/usr/bin/env sh

SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

echo $SELF_PATH

ln -sf $SELF_PATH/bashrc ~/.bashrc
ln -sf $SELF_PATH/screenrc ~/.screenrc
ln -sf $SELF_PATH/vim/vimrc ~/.vimrc
