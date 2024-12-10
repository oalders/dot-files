#!/usr/bin/env bash

set -eu -o pipefail
if is os name ne darwin; then
    exit 0
fi

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# Requires brew "dockutil" to have been run

# apps is a list containing all of the arguments in the dockutil calls below
apps=(
    'App Store'
    'Contacts'
    'Downloads'
    'FaceTime'
    'Finder'
    'Freeform'
    'iTunes'
    'Keynote'
    'Launchpad'
    'Maps'
    'Music'
    'News'
    'Numbers'
    'Notes'
    'Pages'
    'Podcasts'
    'Reminders'
    'Siri'
    'Safari'
    'System Preferences'
    'System Settings'
    'Trash'
    'TV'
)

# iterate over the apps list and remove each app from the dock

for app in "${apps[@]}"; do
    (dockutil --find "$app" && dockutil --remove "$app") || true
done

exit 0
