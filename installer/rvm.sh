#!/usr/bin/env bash

set -eu -o pipefail

if [ "$IS_DARWIN" = false ]; then
    exit 0
fi

\curl -sSL https://get.rvm.io | bash

# Possibly:
# brew link --overwrite coreutils

# Usage:
# rvm install 2.7
# rvm list
# rvm use 2.7.1

exit 0
