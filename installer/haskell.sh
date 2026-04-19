#!/usr/bin/env bash

set -eux

tmpscript=$(mktemp)
trap 'rm -f "$tmpscript"' EXIT
curl --proto '=https' --tlsv1.2 -sSf -o "$tmpscript" https://get-ghcup.haskell.org
sh "$tmpscript"
