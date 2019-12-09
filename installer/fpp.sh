#!/usr/bin/env bash

# Install fpp (Facebook Path Picker)

set -eu -o pipefail

bin_dir=~/local/bin
src_dir=~/local/src

mkdir -p $bin_dir
mkdir -p $src_dir
mkdir -p ~/.fpp

pushd $src_dir > /dev/null

rm -rf PathPicker && git clone --depth 1 https://github.com/facebook/PathPicker.git
pushd PathPicker/ > /dev/null
rm -rf $bin_dir/fpp
ln -s "$(pwd)/fpp" $bin_dir/fpp

# This will fail if "future" needs to be installed
source ~/dot-files/bash_functions.sh
pathadd "$HOME/local/bin"
fpp --version

exit 0
