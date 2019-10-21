#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

if [ $IS_MM = false ]; then
    cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
    cpanm --notest App::cpm
    if [ $(which plenv) ]; then
        plenv rehash
    fi
    cpm install -g --cpanfile cpan/development.cpanfile
    if [ $(which plenv) ]; then
        plenv rehash
    fi
fi

cpm install -g --cpanfile cpan/cli.cpanfile

exit 0
