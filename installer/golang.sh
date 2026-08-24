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

# go.dev no longer serves per-file .sha256 sidecars: the old
# https://go.dev/dl/<file>.sha256 URL now 302s to an HTML redirect page, so
# `sha256sum --check` fails with "no properly formatted checksum lines found".
# Pull the expected checksum from the download manifest JSON instead. Parsed
# with grep (not jq) so this works during a fresh bootstrap before jq exists;
# the "sha256" field sits a few lines below its "filename" in the pretty-printed
# output. `|| true` keeps `set -e`/`pipefail` from aborting on an empty match so
# the explicit check below can report a clear error.
expected="$(
    curl --location --silent "https://go.dev/dl/?mode=json&include=all" \
        | grep -A6 "\"filename\": \"$filename\"" \
        | grep '"sha256"' \
        | grep -oE '[a-f0-9]{64}' \
        | head -1 || true
)"

if [[ -z $expected ]]; then
    echo "Could not determine expected sha256 for $filename from go.dev manifest" >&2
    exit 1
fi

if command -v sha256sum &>/dev/null; then
    echo "$expected  $filename" | sha256sum --check --strict
elif command -v shasum &>/dev/null; then
    echo "$expected  $filename" | shasum -a 256 --check
fi

target=~/local/bin
rm -rf "$target/go"
tar -C "$target" -xzf "$filename"
