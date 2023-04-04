#!/bin/bash

set -eux -o pipefail

apt update
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
apt install -y zip

