#!/usr/bin/env bash

set -eu -o pipefail
# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [[ $IS_SUDOER == false ]]; then
    echo "Skip linux.sh (Not a sudoer)"
    exit 0
fi

set -x

if [[ $IS_DARWIN == false ]]; then
    sudo apt-get install -y -q --no-install-recommends cpanminus curl jq libnet-ssleay-perl pandoc python3-setuptools shellcheck tig
    if [[ $HAS_GO == false ]]; then
        bash installer/golang.sh
    fi

    set +x
    # shellcheck source=bash_functions.sh
    source ~/dot-files/bash_functions.sh
    set -x

    if [[ $HAS_GO == false ]]; then
        echo "Go could not be installed or could not be found"
        exit 1
    fi
fi

exit 0
