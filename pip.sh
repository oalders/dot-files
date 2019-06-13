#!/usr/bin/env bash

set -eu -o pipefail

# Ignore unbound variables for now.  $TRAVIS is triggering an error.
set +u

# future: fix "ImportError: No module named builtins"
# pynvim: required by deoplete
# sqlparse: required by mbra/prettysql
# vint: required by ALE
# yamllint: required by ALE

PIP_INSTALL="future pynvim sqlparse yamllint vint"

# make explicit cases for Travis, MacOS and Linux
if [ $(which pip3) ]; then
    if [[ $TRAVIS = true ]]; then
        pip3 install $PIP_INSTALL
    else
        pip3 install --user --quiet --upgrade $PIP_INSTALL
    fi
else
    which apt-get && sudo apt-get install -y python3-pip
    pip3 install --user --quiet --upgrade $PIP_INSTALL
fi

