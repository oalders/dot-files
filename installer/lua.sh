#!/usr/bin/env bash

set -eux

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

debounce 1 d brew install luarocks

# luarocks install luacheck

debounce 1 d npm install lua-fmt
