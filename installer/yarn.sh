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

yarn config set --home enableTelemetry 0
yarn install

exit 0
