#!/usr/bin/env bash

# https://www.reddit.com/r/golang/comments/tfvb6i/comment/i0ye1r1/?utm_source=share&utm_medium=web2x&context=3

cd /tmp || exit 1
set -eu -o pipefail

version=1.26.0

if is there go && is cli version go gte $version; then
    echo "version $version satisfied"
    exit
fi

arch="$(is known arch)"
os="$(is known os name)"

if [[ $(uname -m) == "armv7l" ]]; then # raspberry pi
    arch="armv6l"
fi

filename="go$version.$os-$arch.tar.gz"
url="https://go.dev/dl/$filename"

curl --location -O "$url"
curl --location -O "https://go.dev/dl/$filename.sha256"

if command -v sha256sum &>/dev/null; then
    echo "$(cat "$filename.sha256")  $filename" | sha256sum --check --strict
elif command -v shasum &>/dev/null; then
    echo "$(cat "$filename.sha256")  $filename" | shasum -a 256 --check
fi
rm -f "$filename.sha256"

target=~/local/bin
rm -rf "$target/go"
tar -C "$target" -xzf "$filename"
