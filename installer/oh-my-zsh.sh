#!/usr/bin/env bash

set -eu -o pipefail

tmpscript=$(mktemp)
trap 'rm -f "$tmpscript"' EXIT
curl -fsSL -o "$tmpscript" https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh
sh "$tmpscript"

exit 0
