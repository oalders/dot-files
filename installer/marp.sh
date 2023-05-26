#!/usr/bin/env bash

set -eu -o pipefail

if eval is os name ne darwin; then
    exit 0
fi

open vscode:extension/marp-team.marp-vscode

exit 0
