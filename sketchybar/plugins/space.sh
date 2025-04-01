#!/bin/sh

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

# $NAME will be space.1, space.2, space.3, etc
# $SELECTED is "true" or "false"
sketchybar --set "$NAME" background.drawing="$SELECTED"
