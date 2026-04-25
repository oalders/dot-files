#!/usr/bin/env bash

# Force the GNOME power profile to 'balanced'. The 'power-saver' profile
# triggers aggressive backlight dimming after a few seconds of inactivity,
# which is unusable for normal work.

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

if is os name ne linux; then
    exit 0
fi

if ! is there powerprofilesctl; then
    echo "Skip power-profile.sh (powerprofilesctl not installed)"
    exit 0
fi

current=$(powerprofilesctl get)
if [[ $current != balanced ]]; then
    powerprofilesctl set balanced
    echo "Power profile: $current -> balanced"
fi
