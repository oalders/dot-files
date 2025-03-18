#!/bin/bash

# sketchybar uses yabai to query the currrent selected space
set -eux -o pipefail

if is os name ne darwin; then
    exit
fi

if ! is there yabai; then
    brew install koekeishiya/formulae/yabai
fi

yabai --start-service

# echo number of current space
yabai -m query --spaces --space | jq '.index'
