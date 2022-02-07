#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source bash_functions.sh

PREFIX=~/dot-files

mkdir -p ~/.config/nvim
mkdir -p ~/.config/oh-my-posh/themes
mkdir -p ~/.config/wezterm
mkdir -p ~/.config/yamllint
mkdir -p ~/.cpanreporter
mkdir -p ~/.npm-packages
mkdir -p ~/.re.pl

ln -sf $LINK_FLAG $PREFIX/dzil ~/.dzil
ln -sf $LINK_FLAG $PREFIX/sqitch ~/.sqitch
ln -sf $PREFIX/ackrc ~/.ackrc
ln -sf $PREFIX/bash_profile ~/.bash_profile
ln -sf $PREFIX/bashrc ~/.bashrc
ln -sf $PREFIX/cpanreporter/config.ini ~/.cpanreporter/config.ini
ln -sf $PREFIX/dataprinter ~/.dataprinter
ln -sf $PREFIX/digrc ~/.digrc
ln -sf $PREFIX/gitignore_global ~/.gitignore_global
ln -sf $PREFIX/golangci.yml ~/.golangci.yml
ln -sf $PREFIX/minicpanrc ~/.minicpanrc
ln -sf $PREFIX/nvim/init.vim ~/.config/nvim/init.vim
ln -sf $PREFIX/oh-my-posh/themes/local.omp.json ~/.config/oh-my-posh/themes/local.omp.json
ln -sf $PREFIX/oh-my-posh/themes/local-tiny.omp.json ~/.config/oh-my-posh/themes/local-tiny.omp.json
ln -sf $PREFIX/oh-my-posh/themes/remote.omp.json ~/.config/oh-my-posh/themes/remote.omp.json
ln -sf $PREFIX/oh-my-posh/themes/remote-tiny.omp.json ~/.config/oh-my-posh/themes/remote-tiny.omp.json
ln -sf $PREFIX/perlcriticrc ~/.perlcriticrc
ln -sf $PREFIX/perltidyrc ~/.perltidyrc
ln -sf $PREFIX/prettierrc.yaml ~/.prettierrc.yaml
ln -sf $PREFIX/profile ~/.profile
ln -sf $PREFIX/proverc ~/.proverc
ln -sf $PREFIX/psqlrc ~/.psqlrc
ln -sf $PREFIX/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf $PREFIX/sqliterc ~/.sqliterc
ln -sf $PREFIX/tigrc ~/.tigrc
ln -sf $PREFIX/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
ln -sf $PREFIX/yamllint.yml ~/.config/yamllint/config

if [ "$IS_DARWIN" = true ]; then
    ln -sf $PREFIX/gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
    ln -sf "$LINK_FLAG" $PREFIX/hammerspoon ~/.hammerspoon
fi

if [ $IS_MM = false ]; then
    ln -sf $PREFIX/npmrc ~/.npmrc
fi

exit 0
