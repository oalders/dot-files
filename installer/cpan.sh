#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

perl --version
cpanm --version
cpanm --verbose --notest App::cpm

cpm install -g --verbose --cpanfile cpan/development.cpanfile
cpm install -g --verbose --verbose --verbose --verbose --verbose --verbose --verbose --verbose --verbose --cpanfile cpan/cli.cpanfile

exit 0

HAS_PLENV=$(which plenv)

if [ $HAS_PLENV ]; then
    plenv rehash
else
    cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
fi

if [ $IS_DARWIN = true ]; then
    # Install Net::SSLeay on MacOS
    export CPPFLAGS="-I/usr/local/opt/openssl/include"
    export LDFLAGS="-L/usr/local/opt/openssl/lib"
fi
cpm install -g --verbose --cpanfile cpan/development.cpanfile
cpm install -g --verbose --verbose --verbose --verbose --verbose --verbose --verbose --verbose --verbose --cpanfile cpan/cli.cpanfile

if [ $HAS_PLENV ]; then
    plenv rehash
fi

exit 0
