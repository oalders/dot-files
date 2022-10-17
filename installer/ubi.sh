#!/bin/bash

set -eu

if [ "$(which ubi)" ]; then
    set -x
    INSTALL_DIR="$HOME/local/bin"
    ubi --project houseabsolute/ubi --in $INSTALL_DIR

    ubi --project houseabsolute/precious --in $INSTALL_DIR
    ubi --project sharkdp/bat --in $INSTALL_DIR
    ubi --project Wilfred/difftastic --exe difft --in $INSTALL_DIR
    # ubi -d --project sharkdp/fd --in $INSTALL_DIR
    exit
fi

curl --silent --location \
    https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
    TARGET=~/local/bin sh
