#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

# https://stackoverflow.com/a/17072017/406224
if [ $IS_DARWIN = true ]; then
    if [ ! $(which brew) ]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    brew config
    brew update
    brew bundle install --file=brew/defaults

    # These packages are installed because they are needed for the Linux tests.
    # It's not clear how to have them not be installed for MacOS on Travis
    if [[ $USER != 'travis' ]]; then
        brew bundle install --file=brew/local-only
        brew install vim -- --with-override-system-vi --without-perl || brew upgrade vim && brew link vim

        if [[ -e ~/local-dot-files/Brewfile ]]; then
            brew bundle install --file=~/local-dot-files/Brewfile
        fi
    fi
fi

exit 0
