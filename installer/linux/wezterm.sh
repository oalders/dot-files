#!/bin/bash

set -eux

FILE=wezterm-nightly.Ubuntu20.04.deb

pushd /tmp || exit 1
curl -LO "https://github.com/wez/wezterm/releases/download/nightly/$FILE"
sudo dpkg -i "$FILE"
