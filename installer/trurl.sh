#!/bin/bash

set -eux -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

dir=trurl

clone_or_update_repo $dir "https://github.com/curl/trurl.git"

if is os name eq linux; then
    sudo apt-get install libcurl4-gnutls-dev
    make
fi

cd $dir
cp trurl "$HOME/local/bin/"
