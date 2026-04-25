#!/usr/bin/env bash

# Install the touchpad-disable-while-typing daemon as a user systemd service.
# Workaround for the Apple SPI Touchpad where libinput's short DWT timeout
# isn't enough to prevent palm touches between keystrokes.

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

if is os name ne linux; then
    exit 0
fi

product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
if [[ $product != MacBook* ]]; then
    echo "Skip touchpad-dwt.sh (not a MacBook: '$product')"
    exit 0
fi

SRC=~/dot-files/linux/touchpad-dwt

# The daemon reads /dev/input/event* which is root:input 0640.
if [[ $IS_SUDOER == true ]]; then
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx input; then
        sudo usermod -aG input "$USER"
        echo "Added $USER to 'input' group. Log out and back in for it to take effect."
    fi
    sudo install -m 0755 "$SRC/touchpad-dwt.py" /usr/local/bin/touchpad-dwt
fi

mkdir -p ~/.config/systemd/user
install -m 0644 "$SRC/touchpad-dwt.service" ~/.config/systemd/user/touchpad-dwt.service

systemctl --user daemon-reload
systemctl --user enable --now touchpad-dwt.service || true
