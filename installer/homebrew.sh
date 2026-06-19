#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

add_path "$HOME/local/bin"

if is os name ne darwin; then
    exit 0
fi

if ! is there brew; then
    tmpscript=$(mktemp)
    trap 'rm -f "$tmpscript"' EXIT
    curl -fsSL -o "$tmpscript" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    /usr/bin/env bash "$tmpscript"
    add_path "/opt/homebrew/bin"
fi

set -x
brew config
brew update -v
brew upgrade

# brew cleanup causes some failures on GitHub around OpenSSL. Those
# failures are hard to debug and probably not helpful to spend time on when
# I so rarely set up a brand new macOS environment.
brew cleanup
brew doctor || true
brew bundle install --file=brew/defaults
brew bundle install --file=brew/local-only
# brew bundle install --file=brew/mas

# macOS ships bash 3.2, which is too old for this setup (e.g. oh-my-posh's
# generated init uses bash 4.2+ syntax like `[[ -v MC_SID ]]`). The brewfile
# above installs a modern bash, so register it and make it the login shell.
brew_bash="$(brew --prefix)/bin/bash"
if [ -x "$brew_bash" ]; then
    if ! grep -qxF "$brew_bash" /etc/shells; then
        echo "$brew_bash" | sudo tee -a /etc/shells >/dev/null
    fi
    current_shell=$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')
    if [ "$current_shell" != "$brew_bash" ]; then
        chsh -s "$brew_bash"
    fi
fi

#if is os version gte 14; then
    #brew install borders
#fi

# if we keep cask "karabiner-elements" in the brewfile we get a dialog asking
# us to choose a keyboard layout every time this file is executed.
if ! brew list --cask | grep karabiner-elements; then
    brew install --cask karabiner-elements
fi

exit 0
