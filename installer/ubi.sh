#!/usr/bin/env bash

set -eux

INSTALL_DIR="$HOME/local/bin"
mkdir -p "$INSTALL_DIR"

if [[ ! "$(command -v curl)" && "$(command -v apt-get)" ]]; then
    if [[ ! "$(command -v sudo)" ]]; then
        apt-get update && apt-get install sudo --autoremove -y
    fi
    apt-get install curl --autoremove -y
fi

if [ ! "$(command -v "$INSTALL_DIR/ubi")" ]; then
    curl --silent --location \
        https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
        TARGET=$INSTALL_DIR sh

else
    "$INSTALL_DIR/ubi" --self-upgrade
fi

"$INSTALL_DIR/ubi" --project oalders/is --in "$INSTALL_DIR"

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
add_path "$INSTALL_DIR"

if ! is there omegasort; then
    ubi --project houseabsolute/omegasort --in "$INSTALL_DIR"
fi

if ! is there precious; then
    ubi --project houseabsolute/precious --in "$INSTALL_DIR"
fi

ubi --project sharkdp/bat --in "$INSTALL_DIR"
ubi --project cli/cli --in "$INSTALL_DIR" --exe gh
# ubi --project sharkdp/fd --in $INSTALL_DIR
# ubi --project Wilfred/difftastic --exe difft --in "$INSTALL_DIR"

exit
