#!/usr/bin/env bash

set -eux

rm -f ~/.cargo/bin/bat
rm -f ~/.cargo/bin/precious

if [[ $IS_DARWIN == true ]]; then
    rm -f ~/.cargo/bin/fd
    brew remove tunnelblick || true
    brew remove vim || true
fi

# path used to be an alias, but that keeps a copy of $PATH in it, which is
# really confusing
alias | grep path && unalias path

# remove some aliases that override real binaries
alias | grep " df=" && unalias df
alias | grep " du=" && unalias du
alias | grep " ls=" && unalias ls
alias | grep " ps=" && unalias ps
