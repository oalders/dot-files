#!/usr/bin/env bash

set -eu -o pipefail

if [[ ("${BASH_VERSINFO[0]}" -lt 4 ) ]]; then
    echo "Need bash version >= 4 to install cz"
    exit 0
fi

if [ "$(which cz)" ]; then
    exit
fi

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

curl -sS https://raw.githubusercontent.com/apathor/cz/master/cz -o ~/local/bin/cz
chmod +x ~/local/bin/cz

exit 0
