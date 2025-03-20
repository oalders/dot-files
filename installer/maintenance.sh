#!/usr/bin/env bash

set -eux

rm -rf ~/.vimtmp
rm -f ~/.cargo/bin/bat
rm -f ~/.cargo/bin/precious

if is os name eq darwin; then
    rm -f ~/.cargo/bin/fd
    if is there brew; then
        packages=(
            "bat"
            "bats-core"
            "dart-sass-embedded"
            "exa"
            "gh"
            "git-delta"
            "nvim"
            "prettier"
            "reattach-to-user-namespace"
        )

        for package in "${packages[@]}"; do
            brew remove "$package" || true
        done

        brew untap homebrew/core || true
    fi
    brew untap Homebrew/homebrew-bundle
    brew untap Homebrew/homebrew-cask-fonts
    brew untap Homebrew/homebrew-services
fi

# path used to be an alias, but that keeps a copy of $PATH in it, which is
# really confusing
alias | grep path && unalias path

# remove some aliases that override real binaries
alias | grep " df=" && unalias df
alias | grep " du=" && unalias du
alias | grep " ls=" && unalias ls
alias | grep " ps=" && unalias ps

exit 0
