#!/usr/bin/env bash

set -eu -o pipefail

./installer/ubi.sh

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

./installer/symlinks.sh

run_installer() {
    echo "running $1"
    echo ""
    time bash "$1"
    echo ""
}

run_installers() {
    local installers=("$@")
    for installer in "${installers[@]}"; do
        run_installer "$installer"
    done
}

add_path "$HOME/local/bin"

run_mac_installers() {
    local mac_installers=(
        ./installer/xcode.sh
        ./installer/homebrew.sh
        # time ./installer/homebrew-maintenance.sh || true
        # ./installer/fonts.sh
        # https://github.com/kcrawford/dockutil/issues/127
        # ./installer/dockutil.sh
        #./configure/dock.sh
        ./installer/lua.sh
    )

    run_installers "${mac_installers[@]}"
}

run_general_installers() {
    local installers=(
        ./installer/linux.sh
        ./installer/maintenance.sh
        ./installer/wezterm.sh
        ./configure/git.sh
        ./configure/ssh.sh
        ./installer/nvim.sh
        ./configure/vim.sh
        ./configure/tmux.sh
        ./installer/npm.sh
        ./installer/cpan.sh
        ./installer/cargo.sh
        ./installer/cz.sh
        ./installer/oh-my-posh.sh
    )

    run_installers "${installers[@]}"
}

if is os name eq darwin; then
    run_mac_installers
fi

run_general_installers

exit 0
