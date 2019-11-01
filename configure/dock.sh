#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

if [ $IS_DARWIN = true ]; then
    # Requires brew "dockutil" to have been run

    dockutil --remove 'App Store'
    dockutil --remove 'Contacts'
    dockutil --remove 'Downloads'
    dockutil --remove 'FaceTime'
    dockutil --remove 'Finder'
    dockutil --remove 'iTunes'
    dockutil --remove 'Launchpad'
    dockutil --remove 'Maps'
    dockutil --remove 'News'
    dockutil --remove 'Notes'
    dockutil --remove 'Podcasts'
    dockutil --remove 'Safari'
    dockutil --remove 'Siri'
    dockutil --remove 'System Preferences'
    dockutil --remove 'Trash'
    dockutil --remove 'TV'

fi

exit 0
