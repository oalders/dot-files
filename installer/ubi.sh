#!/usr/bin/env bash

set -eu

in="$HOME/local/bin"

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

test -d "$in" || mkdir -p "$in"
add_path "$in"

# set -x

# can't use "is" here as we may not yet have it
if [[ ! "$(command -v curl)" && "$(command -v apt-get)" ]]; then
    if [[ ! "$(command -v sudo)" ]]; then
        apt-get update && apt-get install sudo --autoremove -y
    fi
    apt-get install curl --autoremove -y
fi

maybe_install() {
    project="$1"
    shift
    command debounce 1 d ubi --project "$project" --in "$in" "$@"
}

if [ ! -f "$in/ubi" ]; then
    curl --silent --location \
        https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
        TARGET=$in sh

else
    debounce 1 d "$in/ubi" --self-upgrade
fi

if [[ ! -f "$in/is" ]]; then
    ubi --project oalders/is --in "$in"
else
    maybe_install oalders/is
fi

if ! is there debounce; then
    ubi --project oalders/debounce --in "$in"
fi

maybe_install atanunq/viu
maybe_install bensadeh/tailspin --exe tspin
maybe_install crate-ci/typos
maybe_install houseabsolute/omegasort
maybe_install houseabsolute/precious
maybe_install jqlang/jq
maybe_install junegunn/fzf
maybe_install kubernetes-sigs/kustomize
maybe_install oalders/debounce

if is cli output stdout hostname eq wolfblitzer; then
    ubi --url https://github.com/dandavison/delta/releases/download/0.16.5/git-delta_0.16.5_amd64.deb --in /tmp/ubi
    sudo dpkg -i /tmp/ubi/delta
elif is os name eq darwin; then
    maybe_install dandavison/delta
else
    maybe_install dandavison/delta --matching musl
fi

if is os name eq darwin; then
    if is cli version bat ne 0.24.0 || true; then
        ubi --in "$in" \
            --url https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-apple-darwin.tar.gz
    fi
else
    maybe_install sharkdp/bat
fi

maybe_install cli/cli --exe gh

if is there gh && ! gh extension list | grep --quiet copilot; then
    gh extension install github/gh-copilot || true
fi

if  [ "$IS_MM" = false ] && is there gh && ! gh extension list | grep --quiet gh-dash; then
    command debounce 1 d gh extension install dlvhdr/gh-dash || true
fi
