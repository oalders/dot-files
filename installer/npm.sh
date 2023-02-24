#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if [[ $IS_DARWIN == false ]] && [[ $IS_SUDOER == true ]]; then
    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

npm install npm@latest
npm install

if [[ $IS_GITHUB == false ]]; then
    npx --yes npm-merge-driver install --global
fi

exit 0
