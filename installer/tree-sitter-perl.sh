#!/usr/bin/env bash

set -eux

dir=tree-sitter-perl
repo=https://github.com/tree-sitter-perl/tree-sitter-perl.git
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

queries="$HOME/.vim/queries/perl"
mkdir -p "$queries"

cp queries/* "$queries/"

nvim +'TSUninstall perl' +qa
nvim +'TSInstall perl' +qa

exit 0
