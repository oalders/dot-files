#!/bin/bash

cd /tmp || exit

VERSION=tig-2.5.3
rm $VERSION.tar.gz
rm -rf $VERSION

wget https://github.com/jonas/tig/releases/download/$VERSION/$VERSION.tar.gz
tar xzf $VERSION.tar.gz
cd $VERSION

./configure
make prefix=~/local/bin
make install
