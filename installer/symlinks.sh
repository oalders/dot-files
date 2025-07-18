#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source bash_functions.sh

prefix=~/dot-files

directories=(
    "$(bat --config-dir)"
    ~/.config/oh-my-posh/themes
    ~/.config/mcphub
    ~/.config/perlimports
    ~/.config/sqlfluff
    ~/.config/wezterm
    ~/.config/yamllint
    ~/.cpanreporter
    ~/local/bin
    ~/.npm-packages
    ~/.re.pl
)

if is os name eq darwin; then
    directories+=("$HOME/.config/karabiner")
    directories+=("$HOME/hammerspoon")
fi

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
done

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

files=(
    "ackrc"
    "bash_profile"
    "bashrc"
    "dataprinter"
    "digrc"
    "editorconfig"
    "gitignore_global"
    "golangci.yml"
    "inputrc"
    "minicpanrc"
    "perlcriticrc"
    "perltidyrc"
    "prettierrc.yaml"
    "profile"
    "proverc"
    "psqlrc"
    "shellcheckrc"
    "sqliterc"
    "tigrc"
)

if [ "$IS_MM" = false ]; then
    files+=("npmrc")
fi

for file in "${files[@]}"; do
    ln -sf "$prefix/$file" ~/.$file
done

ln -sf $prefix/bat/config "$(bat --config-file)"
ln -sf $prefix/cpanreporter/config.ini ~/.cpanreporter/config.ini
ln -sf $prefix/oh-my-posh/themes/local.omp.json ~/.config/oh-my-posh/themes/local.omp.json
ln -sf $prefix/mcphub/servers.json ~/.config/mcphub/servers.json
ln -sf $prefix/perlimports/perlimports.toml ~/.config/perlimports/perlimports.toml
ln -sf $prefix/config/sqlfluff ~/.config/sqlfluff/.sqlfluff
ln -sf $prefix/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf $prefix/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
ln -sf $prefix/yamllint.yml ~/.config/yamllint/config

if is os name eq darwin; then
    ln -sf "$LINK_FLAG" $prefix/hammerspoon ~/.hammerspoon

    # This pops up a karabiner dialogue asking you to choose a keyboard, so
    # we'll only create the link if it doesn't already exist.
    if [ ! -L ~/.config/karabiner/karabiner.json ]; then
        ln -sf $prefix/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
    fi
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
