#!/usr/bin/env bash

set -eu -o pipefail

cd mm || exit

brew bundle
brew bundle exec -- bundle install

curl "https://raw.githubusercontent.com/gabrielelana/awesome-terminal-fonts/patching-strategy/patched/Droid%2BSans%2BMono%2BAwesome.ttf"> "~/Library/Fonts/Droid Sans Mono Awesome.ttf"
