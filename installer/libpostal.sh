#!/usr/bin/env bash

MYDIR=libpostal

cd /tmp || exit 1
rm -rf $MYDIR
git clone https://github.com/openvenues/libpostal
cd libpostal || exit 1
./bootstrap.sh

DATADIR=$HOME/$MYDIR
mkdir -p "$DATADIR"

./configure --datadir="$DATADIR"
make
sudo make install
