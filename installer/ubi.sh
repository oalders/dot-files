#!/usr/bin/env bash

set -eux

in="$HOME/local/bin"
mkdir -p "$in"

if [[ ! "$(command -v curl)" && "$(command -v apt-get)" ]]; then
    if [[ ! "$(command -v sudo)" ]]; then
        apt-get update && apt-get install sudo --autoremove -y
    fi
    apt-get install curl --autoremove -y
fi

if [ ! "$(command -v "$in/ubi")" ]; then
    curl --silent --location \
        https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
        TARGET=$in sh

else
    "$in/ubi" --self-upgrade
fi

"$in/ubi" --project oalders/is --in "$in"

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
add_path "$in"

if ! is there omegasort; then
    ubi --project houseabsolute/omegasort --in "$in"
fi

if ! is there precious; then
    ubi --project houseabsolute/precious --in "$in"
fi

if is os name eq darwin; then
    if is cli version bat ne 0.23 || true; then
        ubi --in "$in" \
            --url https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-apple-darwin.tar.gz
    fi
else
    ubi --project sharkdp/bat --in "$in"
fi

ubi --project cli/cli --in "$in" --exe gh
ubi --project jqlang/jq --in "$in"
# ubi --project sharkdp/fd --in $in
# ubi --project Wilfred/difftastic --exe difft --in "$in"

exit
