#!/bin/bash

set -eux

curl --silent --location \
    https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
    TARGET=~/local/bin sh