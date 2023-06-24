#!/usr/bin/env bash

set -eu -o pipefail

if is os name ne darwin; then
    exit 0
fi

brew install google-java-format maven
brew cask install oracle-jdk
open vscode:extension/vscjava.vscode-java-pack

exit 0
