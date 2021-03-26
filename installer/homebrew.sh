#!/usr/bin/env bash

set -eux -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
pushd ~/dot-files >/dev/null

# https://stackoverflow.com/a/17072017/406224
if [ "$IS_DARWIN" = true ]; then
    if [ ! "$(which brew)" ]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    brew config
    brew update -v

    if [[ $IS_GITHUB = true ]]; then
        brew unlink bazel || true
        brew unlink python@3.8 || true
    fi

    brew upgrade

    # brew cleanup causes some failures on GitHub around OpenSSL. Those
    # failures are hard to debug and probably not helpful to spend time on when
    # I so rarely set up a brand new macOS environment.
    if [[ $IS_GITHUB = false ]]; then
        brew cleanup
        brew doctor || true
    fi

    if [[ $IS_GITHUB = true ]]; then
        brew unlink node@12 || true
        brew bundle install --file=brew/defaults
    else
        brew bundle install --file=brew/defaults
        brew bundle install --file=brew/local-only
    fi
    if [[ -e ~/local-dot-files/Brewfile ]]; then
        brew bundle install --file=~/local-dot-files/Brewfile
    fi
fi

popd >/dev/null
exit 0
