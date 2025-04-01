#!/bin/bash

# CURRENT_WIFI="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I)"
SSID="$(ipconfig getsummary "$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')" | grep '  SSID : ' | awk -F ': ' '{print $2}')"
NAME=wifi
if [ "$SSID" = "" ]; then
    sketchybar -m --set $NAME label="😭" icon=󰤭
else
    sketchybar -m --set $NAME label="$SSID" icon=
fi
