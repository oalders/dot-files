#!/usr/bin/env bash

# To install everything:
# ./installer/cpan-deps.sh

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

# There are SSL issues on the GitHub macOS install that will cause some module
# installs to fail.
if [[ $IS_DARWIN = true ]] && [[ $IS_GITHUB = true ]]; then
    exit 0
fi

if [ "$IS_MM" = true ]; then
    exit 0
fi

perl --version

# Set up some ENV vars so that global installs go to ~/perl5
if [ "$HAS_PLENV" = false ]; then
    cpanm --local-lib=~/perl5 local::lib && eval "$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
fi

if [[ ! $(which cpm) ]]; then
    curl -fsSL --compressed https://git.io/cpm | perl - install --global App::cpm
fi

if [ "$IS_DARWIN" = true ]; then
    OPENSSL_PREFIX="/usr/local/Cellar/openssl@1.1/1.1.1o"
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
