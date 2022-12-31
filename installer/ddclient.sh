#!/bin/bash

set -eux

sudo apt-get install dh-autoreconf

VERSION=3.10.0
FILE="v$VERSION.tar.gz"

pushd /tmp || exit 1

NAME=ddclient
REPO="$NAME.git"
rm -rf $NAME

git clone "git@github.com:ddclient/$REPO"
cd $NAME || exit 1

./autogen

./configure \
    --prefix=/usr \
    --sysconfdir=/etc/ddclient \
    --localstatedir=/var
make
make VERBOSE=1 check
sudo make install
