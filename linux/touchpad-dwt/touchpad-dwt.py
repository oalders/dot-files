#!/usr/bin/env python3
# Disable the touchpad while typing, re-enable after an idle window.
# Works around libinput's short (~200ms) disable-while-typing timeout on
# the Apple SPI Touchpad, where palms graze the pad between keystrokes.

import glob
import os
import select
import struct
import subprocess
import sys
import time

IDLE_SEC = 0.5
KEYBOARD_NAME = "Apple SPI Keyboard"
EVENT_FMT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FMT)
EV_KEY = 1


def find_keyboard():
    for dev in sorted(glob.glob("/dev/input/event*")):
        name_file = f"/sys/class/input/{os.path.basename(dev)}/device/name"
        try:
            with open(name_file) as f:
                if KEYBOARD_NAME in f.read():
                    return dev
        except OSError:
            continue
    return None


def set_touchpad(enabled):
    subprocess.run(
        [
            "gsettings",
            "set",
            "org.gnome.desktop.peripherals.touchpad",
            "send-events",
            "enabled" if enabled else "disabled",
        ],
        check=False,
    )


def main():
    dev = None
    while dev is None:
        dev = find_keyboard()
        if dev is None:
            time.sleep(5)

    try:
        f = open(dev, "rb", buffering=0)
    except PermissionError:
        print(f"cannot read {dev} — add user to 'input' group", file=sys.stderr)
        sys.exit(1)

    disabled = False
    try:
        while True:
            timeout = IDLE_SEC if disabled else None
            r, _, _ = select.select([f], [], [], timeout)
            if not r:
                if disabled:
                    set_touchpad(True)
                    disabled = False
                continue
            data = f.read(EVENT_SIZE)
            if len(data) != EVENT_SIZE:
                continue
            _, _, typ, _, _ = struct.unpack(EVENT_FMT, data)
            if typ == EV_KEY and not disabled:
                set_touchpad(False)
                disabled = True
    finally:
        if disabled:
            set_touchpad(True)


if __name__ == "__main__":
    main()
