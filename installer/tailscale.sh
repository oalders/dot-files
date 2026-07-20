#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# Tailscale installer.
#
# On macOS: the standalone "macsys" build, not the sandboxed App Store variant --
# needed for full CLI/exit-node/subnet-router behavior. The app auto-updates
# itself once installed, so this script just bootstraps and then no-ops.
#
# On Linux: installed from the official apt repo (pkgs.tailscale.com) rather than
# the snap. The apt package runs unconfined and can read/write anywhere the
# daemon's user can, which the snap's confinement prevents.
# Instructions: https://tailscale.com/download/linux
#
# Not wired into install.sh on purpose -- run this script directly. On Linux,
# switching from the snap drops any active tailnet session, so re-run
# `sudo tailscale up` to authenticate afterwards.

if is os name eq darwin; then
    if [[ -d /Applications/Tailscale.app ]]; then
        exit 0
    fi

    # macOS `installer` requires a .pkg extension, so download into a temp dir.
    workdir="$(mktemp -d "${TMPDIR:-/tmp}/tailscale-install.XXXXXX")"
    trap 'rm -rf "$workdir"' EXIT
    pkg="$workdir/tailscale.pkg"

    curl --fail --silent --show-error --location \
        -o "$pkg" \
        https://pkgs.tailscale.com/stable/Tailscale-latest-macos.pkg

    sudo installer -pkg "$pkg" -target /
    exit 0
fi

if is os name ne linux; then
    echo "skipping. this is $(is known os name)"
    exit 0
fi

if ! is there apt; then
    echo "Skip tailscale.sh (apt not found; only wired up for Debian/Ubuntu)"
    exit 0
fi

if [[ $IS_SUDOER == false ]]; then
    echo "Skip tailscale.sh (Not a sudoer)"
    exit 0
fi

set -x

# Install the apt package *before* removing the snap. Removing the snap first
# tears down its tailscaled and drops the tailnet session, leaving the host with
# no tailscale at all until the apt install finishes -- reorder so a working
# tailscaled is always present.
sudo apt-get install -y -q --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg

CODENAME=$(lsb_release -cs)

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg" |
    sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.tailscale-keyring.list" |
    sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null

sudo apt-get update -q
sudo apt-get install -y -q tailscale

# Now remove the snap so its tailscaled does not fight the apt one over the
# /var/run socket and systemd service.
if snap list tailscale &>/dev/null; then
    sudo snap remove tailscale
fi

# The package enables and starts the daemon on install, but do it explicitly
# (after the snap is gone) so re-runs converge on a running, boot-enabled daemon.
sudo systemctl enable tailscaled
sudo systemctl start tailscaled

sudo systemctl status --no-pager tailscaled

set +x
echo ""
echo "tailscale installed from apt. Authenticate with: sudo tailscale up"
