#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

brew remove bats
brew remove bison
brew remove diff-so-fancy
brew remove fd
brew remove fpp
brew remove geoip
brew remove hub
brew remove lua@5.1
brew remove mercurial
brew remove mysql
brew remove pgcli
brew remove plenv
brew remove postgresql
rm -rf /usr/local/etc/luarocks
rm -rf /usr/local/etc/luarocks51
brew remove truncate

if [ "$IS_MM" = false ]; then
    brew remove virtualbox
fi

brew unlink md5sha1sum
