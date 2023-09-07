#!/bin/bash

set -eux

dir=trurl
repo=https://github.com/curl/trurl.git
src="$HOME/dot-files/src"

mkdir -p "$src"
cd "$src" || exit 1

if [[ -d $dir ]]; then
    cd $dir
    git from
else
    git clone $repo $dir
    cd $dir
fi

sudo apt-get install libcurl4-gnutls-dev
make

cp trurl "$HOME/local/bin/"
