#!/usr/bin/env bash

set -eu -o pipefail

if [ "$IS_DARWIN" = false ]; then
    exit 0
fi

brew cask install visual-studio-code

exit 0
