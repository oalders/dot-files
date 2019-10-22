#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

./installer/homebrew.sh
./configure/dock.sh

./installer/symlinks.sh

git submodule init
git submodule update

./configure/git.sh

./configure/ssh.sh

./installer/pip.sh

./configure/vim.sh

./installer/fpp.sh

./configure/tmux.sh

./installer/linux.sh

./installer/yarn.sh

./installer/cpan.sh

exit 0
