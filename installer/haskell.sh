#!/usr/bin/env bash

set -eux

curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
