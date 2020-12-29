#!/usr/bin/env bash

set -eu -o pipefail
# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if [[ $IS_SUDOER = false ]]; then
    exit 0
fi

set -x

if [[ $IS_DARWIN = false ]]; then
    sudo apt-get install -y -q --no-install-recommends cpanminus curl jq libnet-ssleay-perl nodejs pandoc shellcheck tig tmux
    if [[ $HAS_GO = false ]]; then
        GO_PKG=go1.15.6.linux-amd64.tar.gz
        curl -L -o /tmp/$GO_PKG https://golang.org/dl/go1.15.6.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf /tmp/$GO_PKG
    fi

    set +x
    # shellcheck source=bash_functions.sh
    source ~/dot-files/bash_functions.sh
    set -x

    if [[ $HAS_GO = false ]]; then
        echo "Go could not be installed or could not be found"
        exit 1
    fi
fi

exit 0
