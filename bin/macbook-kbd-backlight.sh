#!/usr/bin/env bash

set -eu -o pipefail

# Control the MacBook internal keyboard backlight on Ubuntu Linux
#
# PROBLEM:
# MacBook Pro keyboards expose their backlight as a sysfs LED on Linux, but
# the macOS F5/F6 brightness keys and Control Center slider don't exist here,
# so there's no obvious way to turn the backlight on or adjust it.
#
# ROOT CAUSE:
# On T2-era MacBooks the applespi driver exposes the backlight at
# /sys/class/leds/spi::kbd_backlight (older models may use a different name
# such as :white:kbd_backlight). Writing to its "brightness" file requires
# root, so it isn't adjustable as a normal user without help.
#
# WHAT THIS SCRIPT DOES:
# 1. Auto-detects the keyboard backlight LED under /sys/class/leds
# 2. Sets, toggles, or steps the brightness
# 3. Prefers brightnessctl (no sudo, persists via its udev rule) and falls
#    back to writing the sysfs file via sudo
#
# USAGE:
#   ./macbook-kbd-backlight.sh                 # show current status
#   ./macbook-kbd-backlight.sh on              # full brightness
#   ./macbook-kbd-backlight.sh off             # turn off
#   ./macbook-kbd-backlight.sh toggle          # off <-> ~50%
#   ./macbook-kbd-backlight.sh up              # +10%
#   ./macbook-kbd-backlight.sh down            # -10%
#   ./macbook-kbd-backlight.sh 50%             # set to 50%
#   ./macbook-kbd-backlight.sh 128             # set to a raw value (0..max)
#
# TIP:
# For sudo-free, repeatable control (e.g. bound to keyboard shortcuts),
# install brightnessctl:  sudo apt install brightnessctl

# --- Locate the keyboard backlight LED -------------------------------------

LED=""
for candidate in /sys/class/leds/*kbd_backlight; do
    if [ -e "$candidate" ]; then
        LED="$candidate"
        break
    fi
done

if [ -z "$LED" ]; then
    echo "Error: no keyboard backlight LED found under /sys/class/leds" >&2
    echo "Available LEDs:" >&2
    find /sys/class/leds/ -maxdepth 1 -mindepth 1 -printf '  %f\n' 2>/dev/null >&2
    exit 1
fi

LED_NAME=$(basename "$LED")
MAX=$(cat "$LED/max_brightness")
CURRENT=$(cat "$LED/brightness")

# --- Helpers ---------------------------------------------------------------

# Clamp a value to the 0..MAX range.
clamp() {
    local value="$1"
    if [ "$value" -lt 0 ]; then
        echo 0
    elif [ "$value" -gt "$MAX" ]; then
        echo "$MAX"
    else
        echo "$value"
    fi
}

# Write a brightness value, preferring brightnessctl to avoid sudo.
set_brightness() {
    local value
    value=$(clamp "$1")

    if command -v brightnessctl &>/dev/null; then
        brightnessctl --device="$LED_NAME" set "$value" >/dev/null
    elif [ -w "$LED/brightness" ]; then
        echo "$value" >"$LED/brightness"
    else
        echo "Need root to write $LED/brightness; using sudo..."
        echo "$value" | sudo tee "$LED/brightness" >/dev/null
    fi

    echo "Keyboard backlight set to $value / $MAX"
}

# Round a percentage of MAX to an integer brightness value.
pct_to_value() {
    local pct="$1"
    echo $(((pct * MAX + 50) / 100))
}

# --- Dispatch --------------------------------------------------------------

ACTION="${1:-status}"
STEP=$(pct_to_value 10)

case "$ACTION" in
status)
    pct=$(((CURRENT * 100 + MAX / 2) / MAX))
    echo "Device:  $LED_NAME"
    echo "Current: $CURRENT / $MAX (${pct}%)"
    echo ""
    echo "Run '$0 on|off|toggle|up|down|<n>|<n>%' to change it."
    ;;
on | max | full)
    set_brightness "$MAX"
    ;;
off | 0)
    set_brightness 0
    ;;
toggle)
    if [ "$CURRENT" -gt 0 ]; then
        set_brightness 0
    else
        set_brightness "$(pct_to_value 50)"
    fi
    ;;
up | +)
    set_brightness "$((CURRENT + STEP))"
    ;;
down | -)
    set_brightness "$((CURRENT - STEP))"
    ;;
*%)
    pct="${ACTION%\%}"
    if ! [[ $pct =~ ^[0-9]+$ ]]; then
        echo "Error: invalid percentage '$ACTION'" >&2
        exit 1
    fi
    set_brightness "$(pct_to_value "$pct")"
    ;;
*)
    if [[ $ACTION =~ ^[0-9]+$ ]]; then
        set_brightness "$ACTION"
    else
        echo "Error: unknown argument '$ACTION'" >&2
        echo "Usage: $0 [status|on|off|toggle|up|down|<n>|<n>%]" >&2
        exit 1
    fi
    ;;
esac
