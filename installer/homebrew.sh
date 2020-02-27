#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh
pushd ~/dot-files > /dev/null

# https://stackoverflow.com/a/17072017/406224
if [ $IS_DARWIN = true ]; then
    if [ ! $(which brew) ]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    brew config
    brew update

    if [[ $IS_GITHUB = true ]]; then
        brew unlink node@6 || true
        brew unlink node@12 || true
        brew unlink libpq   || true
        brew bundle install --file=brew/defaults
    else
        brew bundle install --file=brew/defaults
        brew bundle install --file=brew/local-only
        brew install vim -- --with-override-system-vi --without-perl || brew upgrade vim && brew link vim

    fi
    if [[ -e ~/local-dot-files/Brewfile ]]; then
        brew bundle install --file=~/local-dot-files/Brewfile
    fi
fi

popd > /dev/null
exit 0
