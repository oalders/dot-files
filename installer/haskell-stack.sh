#!/bin/sh

tmpscript=$(mktemp)
trap 'rm -f "$tmpscript"' EXIT
curl -sSL -o "$tmpscript" https://get.haskellstack.org/
sh "$tmpscript"
