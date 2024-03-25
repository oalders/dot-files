#!/bin/bash

set -eux -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

dir='git-fuzzy'

clone_or_update_repo $dir "https://github.com/bigH/git-fuzzy.git"
add_path "./src/$dir"
