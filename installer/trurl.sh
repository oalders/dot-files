#!/bin/bash

set -eux

DIR=trurl
REPO=https://github.com/curl/trurl.git
SRC="$HOME/dot-files/src"

mkdir -p "$SRC"
cd "$SRC" || exit 1

if [[ -d $DIR ]]; then
    cd $DIR
    git from
else
    git clone $REPO $DIR
    cd $DIR
fi

make

prove test.pl
cp trurl "$HOME/local/bin/"

exit 0
