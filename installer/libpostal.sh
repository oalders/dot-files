#!/bin/bash

MYDIR=libpostal

cd /tmp
rm -rf $MYDIR
git clone https://github.com/openvenues/libpostal
cd libpostal
./bootstrap.sh

DATADIR=$HOME/$MYDIR
mkdir -p $DATADIR

./configure --datadir=$DATADIR
make
sudo make install
