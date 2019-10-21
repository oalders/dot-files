#!/usr/bin/env bash

set -eu -o pipefail

alias python='python3'

function pip_install () {
    PIP=$1
    REQUIREMENTS=$2

    # make explicit cases for Travis, MacOS and Linux
    if [ $(which $PIP) ]; then
        if [[ $USER = "travis" ]]; then
            $PIP install -r $REQUIREMENTS
        else
            $PIP install --user --upgrade -r $REQUIREMENTS
        fi
    else
        which apt-get && sudo apt-get install -y python-pip python3-pip
        $PIP install --user -v --upgrade -r $REQUIREMENTS
    fi
}

# The prettysql plugin uses /usr/bin/env python, which finds the first python
# in the path, which will not be python3, so we'll need to double up on
# installing sqlparse for now.
pip_install "pip" "pip/pip-requirements.txt"
pip_install "pip3" "pip/pip3-requirements.txt"

exit 0
