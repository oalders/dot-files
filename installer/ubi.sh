#!/usr/bin/env bash

set -eux

INSTALL_DIR="$HOME/local/bin"

# shellcheck disable=SC1090
source "$HOME/dot-files/bash_functions.sh"

if [ ! "$(command -v ubi)" ]; then
    curl --silent --location \
        https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
        TARGET=$INSTALL_DIR sh
    add_path "$INSTALL_DIR"
fi

ubi --project houseabsolute/ubi --in "$INSTALL_DIR"
ubi --project houseabsolute/precious --in "$INSTALL_DIR"
# ubi --project sharkdp/bat --in "$INSTALL_DIR"
# ubi --project sharkdp/fd --in $INSTALL_DIR
# ubi --project Wilfred/difftastic --exe difft --in "$INSTALL_DIR"

exit
