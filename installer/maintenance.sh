#!/usr/bin/env bash

set -eux

rm -f ~/.cargo/bin/bat
rm -f ~/.cargo/bin/precious

if is os name eq darwin; then
    rm -f ~/.cargo/bin/fd
    if is there brew; then
        brew remove bat || true
        brew remove bats-core || true
        brew remove exa || true
        brew remove gh || true
        brew remove go || true
        brew remove nvim || true
        brew remove prettier || true
        brew untap homebrew/core || true
    fi
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
