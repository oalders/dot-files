#!/usr/bin/env bash

# Run by hand on machines that should keep UTC; not called from install.sh.

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if is os name ne linux; then
    echo "skipping. this is $(is known os name)"
    exit 0
fi

if ! is there timedatectl; then
    echo "Skip timezone-utc.sh (no timedatectl)"
    exit 0
fi

if [[ $(timedatectl show -p Timezone --value) == Etc/UTC ]]; then
    echo "Already on UTC"
    exit 0
fi

sudo timedatectl set-timezone Etc/UTC
timedatectl show -p Timezone --value
