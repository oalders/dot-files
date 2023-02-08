#!/usr/bin/env bash

set -eux -o

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
