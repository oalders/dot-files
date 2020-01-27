#!/usr/bin/env bash

source ~/dot-files/bash_functions.sh

set -eu -o pipefail

function pip_install() {
    PIP=$1
    REQUIREMENTS=$2

    # make explicit cases for Travis, MacOS and Linux
    if [ $(which $PIP) ]; then
        if [[ $USER == "travis" ]]; then
            $PIP install -r $REQUIREMENTS
        else
            $PIP install --user --upgrade -r $REQUIREMENTS
        fi
    else
        which apt-get && sudo apt-get install -y python3-pip
        $PIP install --user -v --upgrade -r $REQUIREMENTS
    fi
}

pip_install "pip3" "pip/pip3-requirements.txt"

exit 0
