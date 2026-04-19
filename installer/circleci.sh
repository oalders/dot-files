#!/usr/bin/env bash

set -eu -o pipefail

tmpscript=$(mktemp)
trap 'rm -f "$tmpscript"' EXIT
curl -fLSs -o "$tmpscript" https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/v0.1.34950/install.sh
bash "$tmpscript"

exit 0
