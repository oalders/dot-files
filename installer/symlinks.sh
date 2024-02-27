#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source bash_functions.sh

prefix=~/dot-files

directories=(
    ~/.config/bat
    ~/.config/oh-my-posh/themes
    ~/.config/perlimports
    ~/.config/wezterm
    ~/.config/yamllint
    ~/.cpanreporter
    ~/local/bin
    ~/.npm-packages
    ~/.re.pl
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
done

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
    ln -sf $prefix/nvim "$nvim_conf_dir"
fi

ln -sf $LINK_FLAG $prefix/dzil ~/.dzil
ln -sf $LINK_FLAG $prefix/sqitch ~/.sqitch

ln -sf $prefix/ackrc ~/.ackrc
ln -sf $prefix/bash_profile ~/.bash_profile
ln -sf $prefix/bashrc ~/.bashrc
ln -sf $prefix/dataprinter ~/.dataprinter
ln -sf $prefix/digrc ~/.digrc
ln -sf $prefix/editorconfig ~/.editorconfig
ln -sf $prefix/gitignore_global ~/.gitignore_global
ln -sf $prefix/golangci.yml ~/.golangci.yml
ln -sf $prefix/inputrc ~/.inputrc
ln -sf $prefix/minicpanrc ~/.minicpanrc
ln -sf $prefix/perlcriticrc ~/.perlcriticrc
ln -sf $prefix/perltidyrc ~/.perltidyrc
ln -sf $prefix/prettierrc.yaml ~/.prettierrc.yaml
ln -sf $prefix/profile ~/.profile
ln -sf $prefix/proverc ~/.proverc
ln -sf $prefix/psqlrc ~/.psqlrc
ln -sf $prefix/shellcheckrc ~/.shellcheckrc
ln -sf $prefix/sqliterc ~/.sqliterc
ln -sf $prefix/tigrc ~/.tigrc

ln -sf $prefix/bat/config ~/.config/bat/config
ln -sf $prefix/cpanreporter/config.ini ~/.cpanreporter/config.ini
ln -sf $prefix/oh-my-posh/themes/local.omp.json ~/.config/oh-my-posh/themes/local.omp.json
ln -sf $prefix/oh-my-posh/themes/local-tiny.omp.json ~/.config/oh-my-posh/themes/local-tiny.omp.json
ln -sf $prefix/oh-my-posh/themes/remote.omp.json ~/.config/oh-my-posh/themes/remote.omp.json
ln -sf $prefix/oh-my-posh/themes/remote-tiny.omp.json ~/.config/oh-my-posh/themes/remote-tiny.omp.json
ln -sf $prefix/perlimports/perlimports.toml ~/.config/perlimports/perlimports.toml
ln -sf $prefix/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf $prefix/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
ln -sf $prefix/yamllint.yml ~/.config/yamllint/config

if is os name eq darwin; then
    ln -sf $prefix/gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
    ln -sf $prefix/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
    ln -sf "$LINK_FLAG" $prefix/hammerspoon ~/.hammerspoon
fi

if [ "$IS_MM" = false ]; then
    ln -sf $prefix/npmrc ~/.npmrc
fi

ln -sf $prefix/bin/add-worktree "$HOME/local/bin/add-worktree"
ln -sf $prefix/bin/remove-worktree "$HOME/local/bin/remove-worktree"
ln -sf $prefix/bin/tm "$HOME/local/bin/tm"

user_dir="$HOME/Library/Application Support/Code/User"
if is os name eq darwin && [ -d "$user_dir" ]; then
    settings="$user_dir/settings.json"
    if [ ! -L "$settings" ]; then
        rm -f "$settings"
        ln -sf $prefix/vscode/user/settings.json "$settings"
    fi
fi

exit 0
