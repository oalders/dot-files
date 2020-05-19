#!/usr/bin/env bash

set -eu -o pipefail

# SSH is disabled by default
# https://www.raspberrypi.org/documentation/remote-access/ssh/
sudo systemctl enable ssh
sudo systemctl start ssh
