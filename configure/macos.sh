#!/usr/bin/env bash

if eval os name ne darwin; then
    exit 0
fi

# Mostly copied directly from
# https://raw.githubusercontent.com/pawelgrzybek/dotfiles/master/setup-macos.sh

set -eux

# System Preferences > Dock > Automatically hide and show the Dock:
defaults write com.apple.dock autohide -bool true

# System Preferences > Dock > Automatically hide and show the Dock (duration)
defaults write com.apple.dock autohide-time-modifier -float 1.0

# System Preferences > Dock > Automatically hide and show the Dock (delay)
defaults write com.apple.dock autohide-delay -float 0

# System Preferences > Dock > Show indicators for open applications
defaults write com.apple.dock show-process-indicators -bool true

# System Preferences > Trackpad > Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# System Preferences > Accessibility > Mouse & Trackpad > Trackpad Potions
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false

# System Preferences > Accessibility > Mouse & Trackpad > Trackpad Potions

# Finder > View > Show Path Bar
defaults write com.apple.finder ShowPathbar -bool true

# Bouncing apps in the dock are distracting
defaults write com.apple.dock no-bouncing -bool TRUE

# Kill affected apps
for app in "Dock" "Finder"; do
    killall "${app}" >/dev/null 2>&1
done

# Done
echo "Done. Note that some of these changes require a logout/restart to take effect."
