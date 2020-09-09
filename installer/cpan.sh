#!/usr/bin/env bash

# To install everything:
# ./installer/cpan-deps.sh

set -eux -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

perl --version

if [[ ! $(which cpm) ]]; then
    curl -fsSL --compressed https://git.io/cpm >/usr/loca/bin/cpm
    chmod +x /usr/local/bin/cpm
    cpm --version
fi

if [ "$IS_DARWIN" = true ]; then
    brew list openssl

    # Install Net::SSLeay on MacOS
    export OPENSSL_PREFIX="/usr/local/Cellar/openssl@1.1/1.1.1g"
fi

cpm install -g --verbose --show-build-log-on-failure --cpanfile cpan/cli.cpanfile

if [ "$HAS_PLENV" = true ]; then
    plenv rehash
fi

exit 0
