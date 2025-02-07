#!/bin/bash

# Inspired by
# Filename: ~/github/dotfiles-latest/sketchybar/felixkratz/plugins/mic.sh

# https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1216899

source "$CONFIG_DIR/plugins/helpers/mic.sh"

# Get the current microphone volume
MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')
set_mic_icon "$MIC_VOLUME"
