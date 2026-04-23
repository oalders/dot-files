#!/usr/bin/env bash

set -eux -o

if is os id eq raspbian; then
    exit 0
fi

tmpscript=$(mktemp)
trap 'rm -f "$tmpscript"' EXIT
curl --proto '=https' --tlsv1.2 -sSf -o "$tmpscript" https://sh.rustup.rs
sh "$tmpscript"
