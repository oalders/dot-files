#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

if [ $IS_DARWIN = true ]; then
    xcode-select --install &>/dev/null || true
fi

exit 0
