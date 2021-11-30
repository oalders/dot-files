#!/bin/bash

set -eu

if [ "$(which ubi)" ]; then
    exit
fi

curl --silent --location \
    https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
    TARGET=~/local/bin sh
