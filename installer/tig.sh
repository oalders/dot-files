#!/usr/bin/env bash

cd /tmp || exit

version=tig-2.5.3
rm $version.tar.gz
rm -rf $version

wget https://github.com/jonas/tig/releases/download/$version/$version.tar.gz
tar xzf $version.tar.gz
cd $version || exit 1

./configure
make prefix=~/local/bin
make install
