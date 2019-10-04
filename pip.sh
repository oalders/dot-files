#!/usr/bin/env bash

set -eu -o pipefail

alias python='python3'

function pip_install () {
    PIP=$1
    PIP_PKGS=$2
    PIP_APT_PKG=$3

    # make explicit cases for Travis, MacOS and Linux
    if [ $(which $PIP) ]; then
        if [[ $USER = "travis" ]]; then
            $PIP install $PIP_PKGS
        else
            $PIP install --user --quiet --upgrade $PIP_PKGS
        fi
    else
        which apt-get && sudo apt-get install -y python-pip
        $PIP install --user --quiet --upgrade $PIP_PKGS
    fi
}

# future: fix "ImportError: No module named builtins"
# pynvim: required by deoplete
# sqlparse: required by mbra/prettysql
# vint: required by ALE
# yamllint: required by ALE

PIP_INSTALL="future pynvim sqlparse yamllint vint"

# The prettysql plugin uses /usr/bin/env python, which finds the first python
# in the path, which will not be python3, so we'll need to double up on
# installing some libraries for now.

pip_install 'pip3' $PIP_INSTALL 'python3-pip'
pip_install "pip" "sqlparse" "python-pip"
