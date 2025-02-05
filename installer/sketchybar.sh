#!/bin/bash

set -eux -o pipefail

brew tap FelixKratz/formulae
brew install sketchybar

ln -s ~/dot-files/sketchybar ~/.config/
brew install --cask font-hack-nerd-font

# for getting inpuc mic name
brew install switchaudio-osx

osascript -e 'tell application "System Events" to set autohide menu bar of dock preferences to true'
