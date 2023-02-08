#!/usr/bin/env bash

# See https://github.com/kcrawford/dockutil/issues/127#issuecomment-1086442131

FILENAME=dockutil.pkg
pushd /tmp || exit 1
rm -f $FILENAME

DLURL=$(curl --silent "https://api.github.com/repos/kcrawford/dockutil/releases/latest" | jq -r .assets[].browser_download_url | grep pkg)
curl -sL ${DLURL} -o $FILENAME
sudo installer -pkg $FILENAME -target /
rm -f $FILENAME
