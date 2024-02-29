#!/usr/bin/env bash

set -eu -o pipefail

if is os name ne darwin; then
    exit 0
fi

if ! is there code; then
   brew install visual-studio-code
fi

open vscode:extension/vscodevim.vim

exit 0
