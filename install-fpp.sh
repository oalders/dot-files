#!/bin/bash

# Install fpp (Facebook Path Picker)

cd ~/local
mkdir -p src
cd src
rm -rf PathPicker && git clone git@github.com:facebook/PathPicker.git
cd PathPicker/
rm -rf ~/local/bin/fpp
ln -s "$(pwd)/fpp" ~/local/bin/fpp
