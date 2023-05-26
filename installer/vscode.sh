#!/usr/bin/env bash

set -eu -o pipefail

if eval is os name ne darwin; then
    exit 0
fi

brew install visual-studio-code
open vscode:extension/vscodevim.vim

exit 0
