#!/bin/bash

set -eu -o pipefail

source "$CONFIG_DIR/plugins/helpers/mic.sh"

# Get the current microphone volume
MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

# Update SketchyBar with the microphone's name and volume
if [[ $MIC_VOLUME -gt 0 ]]; then
    volume=0
else
    volume=100
fi

osascript -e "set volume input volume $volume"
set_mic_icon "$MIC_VOLUME"
