#!/usr/bin/env bash

# To install everything:
# ./installer/cpan-deps.sh

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if [ "$IS_MM" = true ]; then
    exit 0
fi

perl --version

# Set up some ENV vars so that global installs go to ~/perl5
if [ "$HAS_PLENV" = false ]; then
    cpanm --notest --local-lib=~/perl5 local::lib && eval "$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
fi

if ! is there cpm; then
    curl -fsSL --compressed https://raw.githubusercontent.com/skaji/cpm/master/cpm | perl - install --global App::cpm
fi

if is os name eq darwin && [[ ! -d /opt/homebrew ]]; then
    dir=/usr/local/Cellar/openssl@1.1
    prefix=$(ls $dir)
    OPENSSL_PREFIX="${dir}/${prefix}"
    if [[ ! -e $OPENSSL_PREFIX ]]; then
        echo "$OPENSSL_PREFIX does not exist"
        exit 1
    fi
    # Install Net::SSLeay on MacOS
    export OPENSSL_PREFIX
fi

cpm install -g --verbose --show-build-log-on-failure --cpanfile cpan/cli.cpanfile

if [ "$HAS_PLENV" = true ]; then
    plenv rehash
fi

exit 0
