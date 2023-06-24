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

add_path "$HOME/local/bin"

if is os name eq darwin; then
    MAC_INSTALLERS=(
        ./installer/xcode.sh
        ./installer/homebrew.sh
        ./installer/wezterm.sh
        # time ./installer/homebrew-maintenance.sh || true
        # ./installer/fonts.sh

        # https://github.com/kcrawford/dockutil/issues/127
        # ./installer/dockutil.sh
        #./configure/dock.sh
        ./installer/lua.sh
    )

    for f in "${MAC_INSTALLERS[@]}"; do
        run_installer "$f"
    done
fi

INSTALLERS=(
    ./installer/linux.sh
    ./configure/git.sh
    ./configure/ssh.sh
    ./installer/pip.sh
    ./installer/nvim.sh
    ./configure/vim.sh
    ./configure/tmux.sh
    ./installer/npm.sh
    ./installer/cpan.sh
    ./installer/cargo.sh
    ./installer/cz.sh
    ./installer/oh-my-posh.sh
    ./installer/maintenance.sh
)

for f in "${INSTALLERS[@]}"; do
    run_installer "$f"
done

exit 0
