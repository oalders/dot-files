#!/usr/bin/env bash

set -eu -o pipefail

# Ignore unbound variables for now.  $TRAVIS is triggering an error.
set +u

# pynvim is for vim-hug-neovim-rpc
# future: fix "ImportError: No module named builtins"
# pynvim yamllint vint: ALE deps

PIP_INSTALL="future pynvim yamllint vint"

# make explicit cases for Travis, MacOS and Linux
if [ $(which pip) ]; then
    if [ $TRAVIS = true ]; then
        pip install $PIP_INSTALL
    else
        pip install --user --quiet --upgrade pip $PIP_INSTALL
    fi
else
    which apt-get && sudo apt-get install -y python-pip
    pip install --user --quiet --upgrade pip $PIP_INSTALL
fi

