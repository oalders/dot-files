#!/bin/bash

set -euxo pipefail

in=~/local/bin
mkdir -p "$in"
export PATH="$PATH:$in"

curl --silent --location \
    https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
    TARGET="$in" sh

projects=(
    air-verse/air
    eza-community/eza
    hashicorp/terraform
    hetznercloud/cli
    houseabsolute/omegasort
    houseabsolute/precious
    JanDeDobbeleer/oh-my-posh
    jqlang/jq
    junegunn/fzf
    mgdm/htmlq
    oalders/is
    sharkdp/bat
)

for project in "${projects[@]}"; do
    ubi --project "$project" --in "$in"
done

ubi --project cli/cli --exe gh --in "$in"

./installer/claude.sh
./installer/symlinks.sh
./configure/git.sh
