#!/usr/bin/env bash

# https://www.reddit.com/r/golang/comments/tfvb6i/comment/i0ye1r1/?utm_source=share&utm_medium=web2x&context=3

cd /tmp || exit 1
set -eux

LATEST=$(curl https://go.dev/VERSION?m=text)
echo "version $LATEST"

ARCHITECTURE="amd64"

if [[ $(uname -m) == "armv7l" ]]; then # raspberry pi
    ARCHITECTURE="armv6l"
fi

FILENAME="$LATEST".linux-"$ARCHITECTURE".tar.gz

curl --location -O "https://go.dev/dl/$FILENAME"
sudo rm -rf /usr/local/go/
sudo tar -C /usr/local -xzf "$FILENAME"
