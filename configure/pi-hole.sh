#!/usr/bin/env bash

set -eu -o pipefail

# update installed pi-hole
pihole -up

# whitelist domains
pihole -w wundercounter.com www.wundercounter.com
