#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

# https://stackoverflow.com/a/17072017/406224
if [ $IS_DARWIN = true ]; then
    # Install Net::SSLeay on MacOS
    export CPPFLAGS="-I/usr/local/opt/openssl/include"
    export LDFLAGS="-L/usr/local/opt/openssl/lib"

    ./installer/homebrew.sh

    # These packages are installed because they are needed for the Linux tests.
    # It's not clear how to have them not be installed for MacOS on Travis
    if [[ $USER != 'travis' ]]; then

        ./macos/dock.sh

        # Enable tap to click -- may require logout/login
        defaults -currentHost write -globalDomain com.apple.mouse.tapBehavior -int 1

    fi
fi

./installer/symlinks.sh

git submodule init
git submodule update

./configure/git.sh

./configure/ssh.sh

go get github.com/github/hub

# silence warnings when perlbrew not installed
mkdir -p $HOME/perl5/perlbrew/etc
touch $HOME/perl5/perlbrew/etc/bashrc

# deps for vim and fpp
./installer/pip.sh

./configure/vim.sh

./installer/fpp.sh

./configure/tmux.sh

NODE_MODULES='bash-language-server fkill-cli'

./installer/linux.sh

./installer/yarn.sh

./installer/cpan.sh
exit 0
