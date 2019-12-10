#!/usr/bin/env bash

source ~/dot-files/bash_functions.sh

set -eu -o pipefail

alias python='python3'

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
        which apt-get && sudo apt-get install -y python-pip python3-pip
        $PIP install --user -v --upgrade -r $REQUIREMENTS
    fi
}

pip_install "pip3" "pip/pip3-requirements.txt"

# The prettysql plugin uses /usr/bin/env python, which finds the first python
# in the path, which will not be python3, so we'll need to double up on
# installing sqlparse for now.
if [[ $IS_DARWIN == true ]]; then
    add_path "/Users/$USER/Library/Python/2.7/bin"
    if [[ ! $(which pip) ]]; then
        pushd /tmp > /dev/null
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python get-pip.py --user
        popd > /dev/null
    fi
fi

pip_install "pip" "pip/pip-requirements.txt"

exit 0
