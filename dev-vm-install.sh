#!/bin/bash

set -euxo pipefail

in=~/local/bin
mkdir -p $in
export PATH="$PATH:$in"

curl --silent --location \
    https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
    TARGET=$in sh

ubi --project cli/cli --exe gh --in $in
ubi --project houseabsolute/omegasort --in $in
ubi --project houseabsolute/precious --in $in
ubi --project JanDeDobbeleer/oh-my-posh --in $in
ubi --project jqlang/jq --in $in
ubi --project junegunn/fzf --in $in
ubi --project mgdm/htmlq --in $in
ubi --project oalders/is --in $in
ubi --project sharkdp/bat --in $in

./installer/claude.sh
./installer/symlinks.sh
./configure/git.sh

exit 0
