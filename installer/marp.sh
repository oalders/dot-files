#!/usr/bin/env bash

set -eu -o pipefail

if [ "$IS_DARWIN" = false ]; then
    exit 0
fi

open vscode:extension/marp-team.marp-vscode

exit 0
