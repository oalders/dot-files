#!/usr/bin/env bash

set -eu -o pipefail

if is os name eq darwin; then
    xcode-select --install &>/dev/null || true
fi

exit 0
