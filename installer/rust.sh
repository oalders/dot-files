#!/usr/bin/env bash

set -eux -o

if is os id eq raspbian; then
    exit 0
fi

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
