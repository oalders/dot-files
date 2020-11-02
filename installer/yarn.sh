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
# for both MacOS and Linux.  alfred-fkill will prevent a clean install on
# Linux, so we declare it as a dev dependency and don't install dev
# dependencies on "production", which is Linux in this case.
#
# Also, Alfred will not be installed on GitHub, so treat that as a Linux
# install.

if [[ $IS_DARWIN = true ]] && [[ $IS_GITHUB = false ]]; then
    yarn install
else
    yarn install --production=true
fi

exit 0
