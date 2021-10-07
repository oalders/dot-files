#!/usr/bin/env bash

# Ruby installer

set -eu -o pipefail

if [ "$IS_DARWIN" = false ]; then
    exit 0
fi

brew install rbenv

exit 0
