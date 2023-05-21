#!/usr/bin/env bash

set -eux
FILE=gh.deb

pushd /tmp || exit 1

rm -rf $FILE
curl --location https://github.com/cli/cli/releases/download/v2.29.0/gh_2.29.0_linux_amd64.deb -o $FILE
sudo dpkg -i $FILE
popd
