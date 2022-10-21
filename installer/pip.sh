#!/usr/bin/env bash

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -eux -o pipefail

pip_install() {
    PIP=$1
    REQUIREMENTS=$2

    # make explicit cases for Travis, MacOS and Linux
    if [ "$(which "$PIP")" ]; then
        "$PIP" install --user --upgrade -r "$REQUIREMENTS"
    else
        # We want to install recommended packages here
        if [[ $IS_SUDOER = true ]]; then
            which apt-get && sudo apt-get install -y python3-pip
        fi
        "$PIP" install --user -v --upgrade -r "$REQUIREMENTS"
    fi
}

pip_install "pip3" "pip/pip3-requirements.txt"

if [ "$IS_DARWIN" = true ]; then
    # maybe add path if pipx has just been installed
    remove_path "$HOME/Library/Python/3.9/bin"
    add_path "$HOME/Library/Python/3.10/bin"

    /usr/local/opt/python@3.10/bin/python3.10 -m pip install --upgrade pip
    pip3 install ansible

fi

# if [ "$(which pipx)" ]; then
    # pipx install dunk
# fi

exit 0
