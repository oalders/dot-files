#!/bin/bash

set -eux

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

add_path "$HOME/local/bin"

ubi --project houseabsolute/omegasort --in "$HOME/local/bin"
