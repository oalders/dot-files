#!/usr/bin/env bash

# To install everything:
# ./installer/cpan-deps.sh

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

if is var IS_MM true; then
    exit 0
fi

perl --version

# Set up some ENV vars so that global installs go to ~/perl5
if [[ ! -v PLENV_SHELL ]]; then
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
elif ! test -d /usr/include/openssl && is os id eq debian && is user sudoer; then
    sudo apt-get -y install libssl-dev
fi

cpm install -g --verbose --show-build-log-on-failure --cpanfile cpan/cli.cpanfile

# should probably also ensure that Plenv version is not the system Perl
if [[ -v PLENV_SHELL ]]; then
    plenv rehash
fi

exit 0
