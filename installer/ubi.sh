#!/usr/bin/env bash

set -eux

in="$HOME/local/bin"
mkdir -p "$in"

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
add_path "$in"

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
    if is cli age "$in/ubi" gt 7 days; then
        "$in/ubi" --self-upgrade
    fi
fi

maybe_install() {
    local project
    local repo
    IFS='/' read -r project repo <<<"$1"
    if ! is there "$repo" || is cli age "$repo" gt 7 days; then
        shift
        ubi --project "$project/$repo" --in "$in" "$@"
    fi
}

maybe_install crate-ci/typos
maybe_install houseabsolute/omegasort
maybe_install houseabsolute/precious
maybe_install jqlang/jq
maybe_install junegunn/fzf
maybe_install oalders/is
maybe_install kubernetes-sigs/kustomize

if is cli output stdout hostname eq wolfblitzer; then
    ubi --url https://github.com/dandavison/delta/releases/download/0.16.5/git-delta_0.16.5_amd64.deb --in /tmp/ubi
    sudo dpkg -i /tmp/ubi/delta
else
    maybe_install dandavison/delta
fi

if is os name eq darwin; then
    if is cli version bat ne 0.24.0 || true; then
        ubi --in "$in" \
            --url https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-apple-darwin.tar.gz
    fi
else
    ubi --project sharkdp/bat --in "$in"
fi

if ! is there gh || is cli age gh gt 7 days; then
    ubi --project cli/cli --in "$in" --exe gh
fi

if is there gh && ! gh extension list | grep copilot; then
    gh extension install github/gh-copilot || true
fi

if is there gh && ! gh extension list | grep gh-dash; then
    gh extension install dlvhdr/gh-dash || true
fi

exit
