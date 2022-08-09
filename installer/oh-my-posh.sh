#!/usr/bin/env bash

set -eu

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# If you do this, you probably also want to "brew remove oh-my-posh"
if [[ "$IS_DARWIN" = true && -z ${1+x} ]]; then
    echo "Pass a version arg if you want to install oh-my-posh on macOS"
    echo "e.g. ./installer/oh-my-posh.sh v8.27.0"
    exit 0
fi

set -x

DOWNLOAD_FILE=posh-darwin-amd64
TARGET_FILE=oh-my-posh
cd /tmp || exit

if [ "$IS_DARWIN" = false ]; then
    DOWNLOAD_FILE=posh-linux-amd64
fi

if [[ $1 ]]; then
    DOWNLOAD_URL=https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/$1/$DOWNLOAD_FILE
else
    DOWNLOAD_URL=https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/$DOWNLOAD_FILE
fi

curl --fail --location $DOWNLOAD_URL -o $TARGET_FILE
chmod +x $TARGET_FILE
mv $TARGET_FILE ~/local/bin/
