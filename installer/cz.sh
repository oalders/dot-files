#!/usr/bin/env bash

set -eux -o pipefail

if [[ ("${BASH_VERSINFO[0]}" -lt 4 ) ]]; then
    echo "Need bash version >= 4 to install cz"
    exit 0
fi

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

curl -sS https://raw.githubusercontent.com/apathor/cz/master/cz -o /usr/local/bin/cz
chmod +x /usr/local/bin/cz

exit 0
