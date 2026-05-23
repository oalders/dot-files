#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# earlyoom is a userspace OOM killer. It kills memory-hungry processes before
# the system runs out of RAM, avoiding the long freezes the kernel OOM killer
# allows. Not wired into install.sh on purpose -- run this script directly.

if is os name ne linux; then
    echo "skipping. this is $(is known os name)"
    exit 0
fi

if ! is there apt; then
    echo "Skip earlyoom.sh (apt not found; only wired up for Debian/Ubuntu)"
    exit 0
fi

if [[ $IS_SUDOER == false ]]; then
    echo "Skip earlyoom.sh (Not a sudoer)"
    exit 0
fi

set -x

sudo apt-get install -y -q --no-install-recommends earlyoom

# The package enables and starts the service on install, but do it explicitly
# so re-runs converge on a running, boot-enabled daemon.
sudo systemctl enable earlyoom
sudo systemctl start earlyoom

sudo systemctl status --no-pager earlyoom
