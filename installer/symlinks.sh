#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source bash_functions.sh

PREFIX=~/dot-files

mkdir -p ~/.config/bat
mkdir -p ~/.config/oh-my-posh/themes
mkdir -p ~/.config/perlimports
mkdir -p ~/.config/wezterm
mkdir -p ~/.config/yamllint
mkdir -p ~/.cpanreporter
mkdir -p ~/local/bin
mkdir -p ~/.npm-packages
mkdir -p ~/.re.pl

if is os name eq darwin; then
    mkdir -p "$HOME/.config/karabiner"
fi

nvim_conf_dir="$HOME/.config/nvim"
# Simplify after deployed to all environments
if [[ -d $nvim_conf_dir && ! -L $nvim_conf_dir ]]; then
    unlink "$nvim_conf_dir/init.vim"
    rmdir "$nvim_conf_dir"
elif [[ ! -L $nvim_conf_dir ]]; then
    echo "$nvim_conf_dir should create symlink"
    ln -sf $PREFIX/nvim "$nvim_conf_dir"
fi

ln -sf $LINK_FLAG $PREFIX/dzil ~/.dzil
ln -sf $LINK_FLAG $PREFIX/sqitch ~/.sqitch
ln -sf $PREFIX/ackrc ~/.ackrc
ln -sf $PREFIX/bash_profile ~/.bash_profile
ln -sf $PREFIX/bashrc ~/.bashrc
ln -sf $PREFIX/bat/config ~/.config/bat/config
ln -sf $PREFIX/cpanreporter/config.ini ~/.cpanreporter/config.ini
ln -sf $PREFIX/dataprinter ~/.dataprinter
ln -sf $PREFIX/digrc ~/.digrc
ln -sf $PREFIX/editorconfig ~/.editorconfig
ln -sf $PREFIX/gitignore_global ~/.gitignore_global
ln -sf $PREFIX/golangci.yml ~/.golangci.yml
ln -sf $PREFIX/inputrc ~/.inputrc
ln -sf $PREFIX/minicpanrc ~/.minicpanrc
ln -sf $PREFIX/oh-my-posh/themes/local.omp.json ~/.config/oh-my-posh/themes/local.omp.json
ln -sf $PREFIX/oh-my-posh/themes/local-tiny.omp.json ~/.config/oh-my-posh/themes/local-tiny.omp.json
ln -sf $PREFIX/oh-my-posh/themes/remote.omp.json ~/.config/oh-my-posh/themes/remote.omp.json
ln -sf $PREFIX/oh-my-posh/themes/remote-tiny.omp.json ~/.config/oh-my-posh/themes/remote-tiny.omp.json
ln -sf $PREFIX/perlcriticrc ~/.perlcriticrc
ln -sf $PREFIX/perlimports/perlimports.toml ~/.config/perlimports/perlimports.toml
ln -sf $PREFIX/perltidyrc ~/.perltidyrc
ln -sf $PREFIX/prettierrc.yaml ~/.prettierrc.yaml
ln -sf $PREFIX/profile ~/.profile
ln -sf $PREFIX/proverc ~/.proverc
ln -sf $PREFIX/psqlrc ~/.psqlrc
ln -sf $PREFIX/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf $PREFIX/shellcheckrc ~/.shellcheckrc
ln -sf $PREFIX/sqliterc ~/.sqliterc
ln -sf $PREFIX/tigrc ~/.tigrc
ln -sf $PREFIX/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
ln -sf $PREFIX/yamllint.yml ~/.config/yamllint/config

if is os name eq darwin; then
    ln -sf $PREFIX/gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
    ln -sf $PREFIX/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
    ln -sf "$LINK_FLAG" $PREFIX/hammerspoon ~/.hammerspoon
fi

if [ $IS_MM = false ]; then
    ln -sf $PREFIX/npmrc ~/.npmrc
fi

ln -sf $PREFIX/bin/add-worktree "$HOME/local/bin/add-worktree"
ln -sf $PREFIX/bin/remove-worktree "$HOME/local/bin/remove-worktree"

exit 0
