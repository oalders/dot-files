#!/bin/bash
# Poweroff if lid has been closed for >= THRESHOLD seconds.
# Safeguard for 2017 MacBook Pro where suspend is disabled (broken wake)
# and leaving the lid closed risks thermal shutdown inside a bag.
set -eu
THRESHOLD=1800
STATE_FILE=/run/lid-closed-since
LID=$(awk '{print $2}' /proc/acpi/button/lid/LID0/state)
if [ "$LID" = "closed" ]; then
    now=$(date +%s)
    if [ ! -f "$STATE_FILE" ]; then
        echo "$now" > "$STATE_FILE"
        exit 0
    fi
    since=$(cat "$STATE_FILE")
    elapsed=$((now - since))
    if [ "$elapsed" -ge "$THRESHOLD" ]; then
        logger -t lid-closed-poweroff "Lid closed ${elapsed}s >= ${THRESHOLD}s, powering off"
        systemctl poweroff
    fi
else
    rm -f "$STATE_FILE"
fi
