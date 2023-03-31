#!/usr/bin/env bash

set -eux

DIR=tree-sitter-perl
REPO=git@github.com:tree-sitter-perl/tree-sitter-perl.git
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

QUERIES="$HOME/.vim/queries/perl"
mkdir -p "$QUERIES"

cp queries/* "$QUERIES/"

exit 0
