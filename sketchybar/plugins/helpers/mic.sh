#!/bin/bash

set -eu -o pipefail

source "$CONFIG_DIR/colors.sh"

set_mic_icon() {
    if [[ $MIC_VOLUME -eq 0 ]]; then
        sketchybar -m --set mic icon= icon.color="$RED"
    elif [[ $MIC_VOLUME -gt 0 && $MIC_VOLUME -lt 100 ]]; then
        sketchybar -m --set mic icon="" icon.color="$ORANGE"
    elif [[ $MIC_VOLUME -eq 100 ]]; then
        sketchybar -m --set mic icon="" icon.color="$WHITE"
    fi
}
