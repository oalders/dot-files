#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# brew is absent on a fresh Mac until installer/homebrew.sh runs later.
is there brew || exit 0
# Skip the old Ventura box, where Homebrew builds from source.
is os version-codename eq ventura && exit 0

brew list --cask libreoffice &>/dev/null || brew install --cask libreoffice
is there duti || brew install duti

duti -s org.libreoffice.script .xlsx all
