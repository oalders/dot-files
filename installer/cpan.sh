#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

HAS_PLENV=$(which plenv);

if [ $IS_MM = false ]; then
    cpanm --notest App::cpm
    if [ $HAS_PLENV ]; then
        plenv rehash
    else
        cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
    fi
    cpm install -g --cpanfile cpan/development.cpanfile
    if [ $HAS_PLENV ]; then
        plenv rehash
    fi
fi

cpm install -g --cpanfile cpan/cli.cpanfile

exit 0
