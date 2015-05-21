#!/bin/bash

# Install fpp (Facebook Path Picker)

cd ~/local
mkdir -p src
cd src
git clone git@github.com:facebook/PathPicker.git
cd PathPicker/
ln -s "$(pwd)/fpp" ~/local/bin/fpp
