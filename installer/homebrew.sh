#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

add_path "$HOME/local/bin"

if is os name ne darwin; then
    exit 0
fi

if ! is there brew; then
    /usr/bin/env bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    add_path "/opt/homebrew/bin"
fi

set -x
brew config
arch=$(uname -m)
if [[ $arch != 'arm64' ]];then
   brew tap homebrew/core
fi
brew update -v
brew upgrade

# brew cleanup causes some failures on GitHub around OpenSSL. Those
# failures are hard to debug and probably not helpful to spend time on when
# I so rarely set up a brand new macOS environment.
brew cleanup
brew doctor || true
brew bundle install --file=brew/defaults
brew bundle install --file=brew/local-only
# brew bundle install --file=brew/mas

exit 0
