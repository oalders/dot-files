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

run_general_installers() {
    local installers=(
        ./installer/linux.sh
        ./installer/maintenance.sh
        ./configure/git.sh
        ./configure/ssh.sh
        # ./installer/nvim.sh
        # ./configure/vim.sh
        ./configure/tmux.sh
        ./installer/oh-my-posh.sh
    )

    run_installers "${installers[@]}"
}

run_general_installers

exit 0
