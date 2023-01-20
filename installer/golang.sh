#!/bin/bash

# https://www.reddit.com/r/golang/comments/tfvb6i/comment/i0ye1r1/?utm_source=share&utm_medium=web2x&context=3

cd /tmp || exit 1
set -eux

LATEST=$(curl https://go.dev/VERSION?m=text)
echo "version $LATEST"

ARCHITECTURE="amd"

if [[ $(uname -m) = "aarch64" ]]; then
    ARCHITECTURE="arm"
fi

FILENAME="$LATEST".linux-"$ARCHITECTURE"64.tar.gz

curl --location -O "https://go.dev/dl/$FILENAME"
sudo rm -rf /usr/local/go/
sudo tar -C /usr/local -xzf "$FILENAME"
