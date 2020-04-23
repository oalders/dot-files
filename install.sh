#!/usr/bin/env bash

set -eu -o pipefail

git submodule init && git submodule update

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

./installer/xcode.sh

./installer/homebrew.sh

./installer/linux.sh

./configure/dock.sh

./installer/symlinks.sh

./installer/git-submodules.sh

./configure/git.sh

./configure/ssh.sh

./installer/pip.sh

./configure/vim.sh

./installer/fpp.sh

./configure/tmux.sh

./installer/yarn.sh

./installer/cpan.sh

./installer/cargo.sh

exit 0
