#!/bin/bash

set -eu

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

set -x

add_path "$HOME/local/bin"

ubi --project houseabsolute/omegasort --in "$HOME/local/bin"
