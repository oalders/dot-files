#!/usr/bin/env bash

set -eu -o pipefail
source ~/dot-files/bash_functions.sh

if [ $IS_DARWIN = false ]; then
    sudo apt-get install -y libnet-ssleay-perl nodejs pandoc
fi

exit 0
