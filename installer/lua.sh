#!/bin/bash

set -eux

brew install luarocks

luarocks install luacheck

npm install lua-fmt
