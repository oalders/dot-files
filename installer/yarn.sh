#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if [[ $(command -v yarn -v) ]]; then
    echo "yarn already installed"
else
    rm -rf "$HOME/.yarn"
    curl -o- -L https://yarnpkg.com/install.sh | bash
    add_path "$HOME/.yarn/bin"
fi

if [[ $IS_DARWIN = false ]] && [[ $IS_SUDOER = true ]]; then
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# The --production flag is a hack which allows us to use the same package.json
# for both MacOS and Linux.  A macOS dependency can prevent a clean install on
# Linux, so we declare macOS requirements as dev dependencies and won't install
# dev dependencies on "production", which is Linux in this case.
#
# I'm removing alfred-fkill as it's no longer maintained and fzf's kill
# integration is amazing, but I'll leave this logic in place for the next
# macOS-only dependency.

if [[ $IS_DARWIN = true ]] && [[ $IS_GITHUB = false ]]; then
    yarn install
else
    yarn install --production=true
fi

exit 0
