#!/usr/bin/env bash

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -eux -o pipefail

pip_install() {
    pip=$1
    requirements=$2

    # make explicit cases for Travis, MacOS and Linux
    if is there pip; then
        "$pip" install --user --upgrade -r "$requirements"
    else
        # We want to install recommended packages here
        if [[ $IS_SUDOER == true ]]; then
            is there apt-get && sudo apt-get install -y python3-pip
        fi
        "$pip" install --user -v --upgrade -r "$requirements"
    fi
}

pip_install "pip3" "pip/pip3-requirements.txt"

if is os name eq darwin; then
    python3 -m pip install --upgrade pip
    pip3 install ansible
fi

# if [ "$(which pipx)" ]; then
# pipx install dunk
# fi

exit 0
