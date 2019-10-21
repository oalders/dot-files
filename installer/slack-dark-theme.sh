#!/bin/sh

# Install a proper dark theme for Slack. This should no longer be necessary now
# that Slack has built in dark theme support.

set -eu -o pipefail

SRC_DIR=~/local/src

mkdir -p $SRC_DIR
pushd $SRC_DIR

REPO_NAME=slack-black-theme

rm -rf $REPO_NAME && git clone --depth 1 git@github.com:caiceA/$REPO_NAME.git

FONT_FOLDER=muli_font
rm -rf $FONT_FOLDER && mkdir -p $FONT_FOLDER
ZIP_NAME=muli.zip

pushd $FONT_FOLDER
curl https://www.fontsquirrel.com/fonts/download/muli > $ZIP_NAME

unzip muli.zip
cp *.ttf ~/Library/Fonts/
popd

npm i -g npx asar

echo $(pwd)
pushd $REPO_NAME
./slack-dark-mode.sh
popd

exit 0
