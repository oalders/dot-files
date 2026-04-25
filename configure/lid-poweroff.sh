#!/usr/bin/env bash

# Configure lid-close behavior on a 2017 MacBook Pro running Ubuntu, where
# suspend reliably fails to wake. Disables all suspend/sleep paths and
# installs a systemd timer that powers the machine off if the lid stays
# closed for 30 minutes (safeguard against thermal shutdown in a bag).

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

if is os name ne linux; then
    exit 0
fi

if [[ $IS_SUDOER == false ]]; then
    echo "Skip lid-poweroff.sh (Not a sudoer)"
    exit 0
fi

# Only apply on a MacBook (matches MacBookPro*, MacBook*, etc).
product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
if [[ $product != MacBook* ]]; then
    echo "Skip lid-poweroff.sh (not a MacBook: '$product')"
    exit 0
fi

SRC=~/dot-files/linux/lid-poweroff

# GNOME: don't suspend on lid close or battery idle.
if is there gsettings; then
    gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
fi

# logind: ignore lid switch at the system level (covers lock/login screen).
sudo mkdir -p /etc/systemd/logind.conf.d
sudo install -m 0644 "$SRC/nosleep-logind.conf" /etc/systemd/logind.conf.d/00-nosleep.conf

# Mask all sleep targets so nothing can suspend the machine.
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Install the lid-closed poweroff safeguard.
sudo install -m 0755 "$SRC/lid-closed-poweroff.sh" /usr/local/sbin/lid-closed-poweroff.sh
sudo install -m 0644 "$SRC/lid-closed-poweroff.service" /etc/systemd/system/lid-closed-poweroff.service
sudo install -m 0644 "$SRC/lid-closed-poweroff.timer" /etc/systemd/system/lid-closed-poweroff.timer

# Don't restart systemd-logind here: doing it from a running graphical
# session tears down the session bus and locks the user out of GDM until
# the next boot. The logind drop-in is read at startup, so the lid-close
# override takes effect on the next reboot.
sudo systemctl daemon-reload
sudo systemctl enable --now lid-closed-poweroff.timer
