#!/bin/bash

set -eux -o pipefail

brew tap FelixKratz/formulae
brew install sketchybar

ln -s ~/dot-files/sketchybar ~/.config/
brew install --cask font-hack-nerd-font
