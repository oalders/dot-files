#!/bin/bash

set -eu -o pipefail

default_folder=~/Documents/screenshots
mkdir -p $default_folder

current_folder=$(defaults read com.apple.screencapture location)

echo "$current_folder"
if [[ "$current_folder" != "$default_folder" ]]; then
    defaults write com.apple.screencapture location $default_folder
    killall SystemUIServer
fi
