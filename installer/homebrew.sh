#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [ "$IS_DARWIN" = false ]; then
    exit 0
fi

if [ ! "$(which brew)" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

set -x
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
if [[ $IS_GITHUB = true ]]; then
    brew unlink node@12 || true
    brew bundle install --file=brew/defaults
else
    brew cleanup
    brew doctor || true
    brew bundle install --file=brew/defaults
    brew bundle install --file=brew/local-only
fi

if [[ -e ~/local-dot-files/Brewfile ]]; then
    brew bundle install --file=~/local-dot-files/Brewfile
fi

exit 0
