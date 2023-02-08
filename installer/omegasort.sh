#!/usr/bin/env bash

set -eu

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

add_path "$HOME/local/bin"

set -x

ubi --project houseabsolute/omegasort --in "$HOME/local/bin"
