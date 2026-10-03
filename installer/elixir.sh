#!/usr/bin/env bash

set -eu -o pipefail

otp_version=29.1.1
elixir_version=1.20.2

otp_dir="$HOME/local/otp/$otp_version"
elixir_dir="$HOME/local/elixir/$elixir_version"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/elixir.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

fetch_hex() {
    local base=$1 name=$2 file=$3
    curl -fsSL -o "$tmp/$file" "$base/$file"
    local sum
    sum=$(curl -fsSL "$base/builds.txt" | awk -v n="$name" '$1 == n { print $4 }')
    echo "$sum  $tmp/$file" | shasum -a 256 -c -
}

if [[ ! -x "$otp_dir/bin/erl" ]]; then
    mkdir -p "$otp_dir"
    arch=$(uname -m)
    if is os name eq darwin; then
        [[ $arch == arm64 ]] || arch=amd64
        curl -fsSL -o "$tmp/otp.tar.gz" \
            "https://github.com/erlef/otp_builds/releases/download/OTP-$otp_version/OTP-$otp_version-macos-$arch.tar.gz"
        tar -xzf "$tmp/otp.tar.gz" -C "$otp_dir" --strip-components=1
    else
        # shellcheck disable=SC1091
        . /etc/os-release
        base="https://builds.hex.pm/builds/otp"
        [[ $arch == aarch64 ]] && base="$base/arm64"
        base="$base/$ID-$VERSION_ID"
        fetch_hex "$base" "OTP-$otp_version" "OTP-$otp_version.tar.gz"
        tar -xzf "$tmp/OTP-$otp_version.tar.gz" -C "$otp_dir" --strip-components=1
        # Rewrites the build-time paths baked into the release to $otp_dir.
        "$otp_dir/Install" -minimal "$otp_dir"
    fi
fi

if [[ ! -x "$elixir_dir/bin/elixir" ]]; then
    otp_major=${otp_version%%.*}
    file="v$elixir_version-otp-$otp_major.zip"
    fetch_hex https://builds.hex.pm/builds/elixir "${file%.zip}" "$file"
    mkdir -p "$elixir_dir"
    unzip -q "$tmp/$file" -d "$elixir_dir"
fi

# bashrc puts these "current" links on PATH.
ln -sfn "$otp_dir" "$HOME/local/otp/current"
ln -sfn "$elixir_dir" "$HOME/local/elixir/current"

PATH="$HOME/local/elixir/current/bin:$HOME/local/otp/current/bin:$PATH"
elixir --version
