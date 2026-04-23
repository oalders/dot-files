#!/bin/bash

set -eux -o pipefail

apt update
tmpscript=$(mktemp)
trap 'rm -f "$tmpscript"' EXIT
curl -sS -o "$tmpscript" https://getcomposer.org/installer
php "$tmpscript" -- --install-dir=/usr/local/bin --filename=composer
apt install -y zip
