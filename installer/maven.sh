#!/usr/bin/env bash

set -eu -o pipefail

if [ "$IS_DARWIN" = false ]; then
    exit 0
fi

brew install maven
open vscode:extension/vscjava.vscode-java-pack

exit 0
