#!/bin/bash

FILE=nvim.appimage

cd /tmp || exit
rm -f $FILE
curl -LO https://github.com/neovim/neovim/releases/latest/download/$FILE
chmod u+x $FILE
mv $FILE ~/local/bin/
