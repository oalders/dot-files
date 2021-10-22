#!/usr/bin/env bash

# Install fpp (Facebook Path Picker)

set -eux -o pipefail

bin_dir=~/local/bin
src_dir=~/local/src

mkdir -p $bin_dir
mkdir -p $src_dir
mkdir -p ~/.fpp

pushd $src_dir > /dev/null

rm -rf PathPicker && git clone https://github.com/facebook/PathPicker.git
pushd PathPicker/ > /dev/null
git checkout 0.9.2
rm -rf $bin_dir/fpp
ln -s "$(pwd)/fpp" $bin_dir/fpp

set +x
# This will fail if "future" needs to be installed
# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
add_path "$HOME/local/bin"
fpp --version

exit 0
