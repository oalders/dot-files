#!/bin/bash

# Install fpp (Facebook Path Picker)

set -eu -o pipefail

bin_dir=~/local/bin
src_dir=~/local/src

mkdir -p $bin_dir
mkdir -p $src_dir

pushd $src_dir

rm -rf PathPicker && git clone git@github.com:facebook/PathPicker.git
pushd PathPicker/
rm -rf $bin_dir/fpp
ln -s "$(pwd)/fpp" $bin_dir/fpp
