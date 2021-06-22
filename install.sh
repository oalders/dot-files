#!/usr/bin/env bash

set -eu -o pipefail

git submodule init && git submodule update

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if [[ $IS_DARWIN = true ]]; then
    ./installer/xcode.sh
    ./installer/homebrew.sh
    ./configure/dock.sh
fi

./installer/linux.sh

./installer/symlinks.sh

./installer/git-submodules.sh

./configure/git.sh

./installer/fpp.sh

./configure/ssh.sh

./installer/pip.sh

./installer/vim.sh

./configure/vim.sh

./configure/tmux.sh

./installer/npm.sh

./installer/cpan.sh

./installer/cargo.sh

./installer/cz.sh

exit 0
