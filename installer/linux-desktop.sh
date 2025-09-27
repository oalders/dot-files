#!/bin/bash

set -euo pipefail

sudo apt-get install \
    chromium-browser \
    docker-compose-v2 \
    gnome-tweaks \
    net-tools \
    openssh-server \
    sqlite3

sudo systemctl enable ssh
sudo systemctl start ssh
