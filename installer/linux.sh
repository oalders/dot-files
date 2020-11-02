#!/usr/bin/env bash

set -eu -o pipefail
# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [[ $IS_SUDOER = false ]]; then
    exit 0
fi

set -x

if [[ $IS_DARWIN = false ]]; then
    sudo apt-get install -y --no-install-recommends cpanminus curl jq libnet-ssleay-perl nodejs pandoc shellcheck tig tmux
    if [[ $HAS_GO = false ]]; then
        sudo apt-get install -y --no-install-recommends golang-go
    fi
fi

exit 0
