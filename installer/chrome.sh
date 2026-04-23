#!/bin/bash

set -eu -o pipefail

# Installs Google Chrome from the vendor apt repo so superpowers-chrome can
# find /usr/bin/google-chrome. Linux-only; skips cleanly on macOS (where
# Chrome is installed as an app bundle by hand or homebrew).

if [[ $(uname -s) != Linux ]]; then
    exit 0
fi

if command -v google-chrome >/dev/null; then
    exit 0
fi

keyring=/usr/share/keyrings/google-linux-signing-key.gpg
sources=/etc/apt/sources.list.d/google-chrome.list

if [[ ! -f $keyring ]]; then
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub |
        sudo gpg --dearmor -o "$keyring"
fi

if [[ ! -f $sources ]]; then
    echo "deb [arch=amd64 signed-by=$keyring] https://dl.google.com/linux/chrome/deb/ stable main" |
        sudo tee "$sources" >/dev/null
fi

sudo apt-get update
sudo apt-get install -y google-chrome-stable
