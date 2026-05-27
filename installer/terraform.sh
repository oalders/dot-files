#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# Installs the Terraform CLI from HashiCorp's official APT repo, so future
# upgrades come along with `apt-get upgrade`. Debian/Ubuntu only.

if is os name ne linux; then
    echo "skipping. this is $(is known os name)"
    exit 0
fi

if ! is there apt; then
    echo "Skip terraform.sh (apt not found; only wired up for Debian/Ubuntu)"
    exit 0
fi

if [[ $IS_SUDOER == false ]]; then
    echo "Skip terraform.sh (Not a sudoer)"
    exit 0
fi

keyring=/etc/apt/keyrings/hashicorp.gpg
sources_list=/etc/apt/sources.list.d/hashicorp.list

set -x

if [[ ! -f $keyring ]]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://apt.releases.hashicorp.com/gpg |
        sudo gpg --dearmor -o "$keyring"
    sudo chmod a+r "$keyring"
fi

if [[ ! -f $sources_list ]]; then
    echo "deb [signed-by=$keyring] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
        sudo tee "$sources_list" >/dev/null
    sudo apt-get update -q
fi

sudo apt-get install -y -q --no-install-recommends terraform
