#!/bin/bash

set -eu -o pipefail

tmpscript=$(mktemp)
trap 'rm -f "$tmpscript"' EXIT
curl -o "$tmpscript" https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh
bash "$tmpscript"
nvm install 20
