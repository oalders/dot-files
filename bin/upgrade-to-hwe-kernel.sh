#!/bin/bash

set -eu -o pipefail

# Upgrades Ubuntu 24.04 to the HWE kernel track (currently 6.17+).
# Motivation: nono sandbox features (Landlock V6 signal scoping) need kernel >= 6.12.
# Old kernels stay installed; GRUB lets you pick a previous kernel on boot if needed.
#
# Run only after taking a VM snapshot / backup.

sudo apt update
sudo apt install -y linux-generic-hwe-24.04

echo
echo "Installed. Reboot to use the new kernel:"
echo "  sudo reboot"
echo
echo "After reboot, verify with: uname -r"
