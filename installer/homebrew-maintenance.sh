#!/usr/bin/env bash

#set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

brew remove ansible
brew remove bats
brew remove bison
brew remove diff-so-fancy
brew remove erlang@20
brew remove fd
brew remove geoip
brew remove ghc@8.2
brew remove hub
brew remove isl@0.18
brew remove lua@5.1
brew remove mercurial
brew remove mysql
brew remove node@10
brew remove oh-my-posh
brew remove pgcli
brew remove php@5.6
brew remove php56-mcrypt
brew remove phppgadmin
brew remove plenv
brew remove postgresql
brew remove python@2

brew unlink md5sha1sum

rm -rf /usr/local/etc/luarocks
rm -rf /usr/local/etc/luarocks51
brew remove truncate

if [ "$IS_MM" = false ]; then
    brew remove virtualbox
fi

brew untap caskroom/cask
