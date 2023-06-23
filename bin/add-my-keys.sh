#!/bin/bash

set -eux -o pipefail

curl -s https://github.com/oalders.keys >~/.ssh/authorized_keys
