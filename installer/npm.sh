#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

target_version=20
if is os name eq linux && is cli version --major node lt $target_version && is user sudoer; then
    curl -sL https://deb.nodesource.com/setup_$target_version.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

debounce 1 d npm install npm@latest
debounce 1 d npm install

if [[ $IS_GITHUB == false ]] && is os name eq darwin; then
    mkdir -p "$HOME/.npm-packages/lib"
    npx --yes npm-merge-driver install --global
fi

exit 0
