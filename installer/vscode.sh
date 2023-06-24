#!/usr/bin/env bash

set -eu -o pipefail

if is os name ne darwin; then
    exit 0
fi

brew install visual-studio-code
open vscode:extension/vscodevim.vim

exit 0
