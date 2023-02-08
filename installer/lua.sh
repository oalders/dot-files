#!/usr/bin/env bash

set -eux

brew install luarocks

luarocks install luacheck

npm install lua-fmt
