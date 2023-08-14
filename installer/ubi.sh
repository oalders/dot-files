#!/usr/bin/env bash

set -eux

install_dir="$HOME/local/bin"
mkdir -p "$install_dir"

if [[ ! "$(command -v curl)" && "$(command -v apt-get)" ]]; then
    if [[ ! "$(command -v sudo)" ]]; then
        apt-get update && apt-get install sudo --autoremove -y
    fi
    apt-get install curl --autoremove -y
fi

if [ ! "$(command -v "$install_dir/ubi")" ]; then
    curl --silent --location \
        https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
        TARGET=$install_dir sh

else
    "$install_dir/ubi" --self-upgrade
fi

"$install_dir/ubi" --project oalders/is --in "$install_dir"

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
add_path "$install_dir"

if ! is there omegasort; then
    ubi --project houseabsolute/omegasort --in "$install_dir"
fi

if ! is there precious; then
    ubi --project houseabsolute/precious --in "$install_dir"
fi

if is os name eq darwin; then
    ubi --in "$install_dir" \
        --url https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-apple-darwin.tar.gz
else
    ubi --project sharkdp/bat --in "$install_dir"
fi

ubi --project cli/cli --in "$install_dir" --exe gh
# ubi --project sharkdp/fd --in $install_dir
# ubi --project Wilfred/difftastic --exe difft --in "$install_dir"

exit
