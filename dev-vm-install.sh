#!/bin/bash

set -euxo pipefail

if [[ -z "${GITHUB_TOKEN:-}" ]] && gh auth token &>/dev/null; then
    GITHUB_TOKEN=$(gh auth token)
    export GITHUB_TOKEN
fi

in=~/local/bin
mkdir -p "$in"
export PATH="$PATH:$in"

UBI_VERSION=v0.9.0
curl --silent --location \
    "https://raw.githubusercontent.com/houseabsolute/ubi/$UBI_VERSION/bootstrap/bootstrap-ubi.sh" |
    TARGET="$in" sh

projects=(
    air-verse/air
    eza-community/eza
    # hashicorp/terraform
    # hetznercloud/cli
    houseabsolute/omegasort
    houseabsolute/precious
    JanDeDobbeleer/oh-my-posh
    jqlang/jq
    junegunn/fzf
    mgdm/htmlq
    oalders/is
    sharkdp/bat
)

retry_ubi() {
    local max_attempts=3
    for attempt in $(seq 1 $max_attempts); do
        if ubi "$@"; then
            return 0
        fi
        echo "ubi failed (attempt $attempt/$max_attempts): $*"
        sleep 5
    done
    echo "ubi gave up after $max_attempts attempts: $*"
    return 1
}

for project in "${projects[@]}"; do
    retry_ubi --project "$project" --in "$in"
done

retry_ubi --project cli/cli --exe gh --in "$in"

retry_ubi --project hetznercloud/cli --exe hcloud --in "$in"

./installer/claude.sh
./installer/symlinks.sh
./configure/git.sh
