#!/usr/bin/env bash

# Ruby installer

set -eu -o pipefail

if is os name ne darwin; then
    exit 0
fi

brew install rbenv

exit 0
