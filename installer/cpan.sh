#!/usr/bin/env bash

# To install everything:
# find cpan | grep cpanfile | xargs -n 1 cpm install -g --cpanfile

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

perl --version
cpanm --version

if [ "$HAS_PLENV" = false ]; then
    cpanm --local-lib=~/perl5 local::lib && eval "$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
fi

cpanm --notest App::cpm

if [ "$HAS_PLENV" = true ]; then
    echo "HAS PLENV"
    plenv rehash
else
    add_path "$HOME/perl5/bin"
fi

if [ "$IS_DARWIN" = true ]; then
    # Install Net::SSLeay on MacOS
    export CPPFLAGS="-I/usr/local/opt/openssl/include"
    export LDFLAGS="-L/usr/local/opt/openssl/lib"
fi

cpm install -g --verbose --cpanfile cpan/cli.cpanfile

if [ "$HAS_PLENV" = true ]; then
    plenv rehash
fi

exit 0
