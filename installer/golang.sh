#!/usr/bin/env bash

# https://www.reddit.com/r/golang/comments/tfvb6i/comment/i0ye1r1/?utm_source=share&utm_medium=web2x&context=3

cd /tmp || exit 1
set -eux

latest=$(curl https://go.dev/VERSION?m=text)
echo "version $latest"

arch="amd64"

if [[ $(uname -m) == "armv7l" ]]; then # raspberry pi
    arch="armv6l"
fi

filename="$latest".linux-"$arch".tar.gz

curl --location -O "https://go.dev/dl/$filename"
sudo rm -rf /usr/local/go/
sudo tar -C /usr/local -xzf "$filename"
