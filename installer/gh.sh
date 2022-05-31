#!/bin/bash

set -eux
FILE=gh.deb

pushd /tmp || exit 1

rm -rf $FILE
curl --location https://github.com/cli/cli/releases/download/v2.11.3/gh_2.11.3_linux_amd64.deb -o $FILE
sudo dpkg -i $FILE
popd
