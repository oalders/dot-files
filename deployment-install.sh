#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

run_installer() {
    echo "running $1"
    echo ""
    time bash "$1"
    echo ""
}

INSTALLERS=(
    ./installer/linux.sh
    ./installer/symlinks.sh
    ./configure/git.sh
#    ./configure/ssh.sh
#    ./installer/pip.sh
    ./installer/nvim.sh
    ./configure/vim.sh
    ./configure/tmux.sh
    ./installer/npm.sh
#    ./installer/cpan.sh
#    ./installer/cargo.sh
    ./installer/ubi.sh
    ./installer/oh-my-posh.sh
)

for f in "${INSTALLERS[@]}"; do
    run_installer "$f"
done

exit 0
