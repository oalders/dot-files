#!/bin/bash

set -eu -o pipefail

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

source "$CONFIG_DIR/colors.sh"

ICON_COLOR="$WHITE"
if [ "$SENDER" = "volume_change" ]; then
    VOLUME="$INFO"

    case "$VOLUME" in
    [6-9][0-9] | 100)
        ICON="󰕾" ICON_COLOR="$GREEN"
        ;;
    [3-5][0-9])
        ICON="󰖀"
        ;;
    [1-9] | [1-2][0-9])
        ICON="󰕿"
        ;;
    *) ICON="󰖁" ICON_COLOR="$RED" ;;
    esac

    sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%" icon.color="$ICON_COLOR"
fi
