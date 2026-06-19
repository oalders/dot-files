#!/usr/bin/env bash

# SC2016: the single-quoted `bash -c` bodies are intentional; $1/$2 are expanded
#         by the child shell, not here.
# SC2329: wait_for_input/alfred_metacpan are invoked indirectly via `bash -c`.
# shellcheck disable=SC2016,SC2329

set -eu

cd /tmp

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# Alfred won't let you add multiple workflows at once.
# `debounce` is an external binary that execs its argument, so it cannot call
# a bash function directly. Export the function and invoke it through `bash -c`
# so the child shell inherits it.
wait_for_input() {
    url=$1
    file=$2
    rm -f "$file"

    curl --location -O "$url/$file"
    open "$file"

    # `debounce` runs us without a usable stdin, so read the keypress straight
    # from the controlling terminal instead.
    read -n 1 -s -r -p "Press any key to continue" </dev/tty
    echo
}
export -f wait_for_input

set -x
debounce 90 d bash -c 'wait_for_input "$1" "$2"' _ 'https://alfred.app/workflows/rknightuk/http-status-codes/download/' 'http-status-codes.alfredworkflow'
debounce 90 d bash -c 'wait_for_input "$1" "$2"' _ 'https://github.com/alexchantastic/alfred-ip-address-workflow/releases/download/v1.0.3' 'alfred-ip-address-workflow.alfredworkflow'
debounce 90 d bash -c 'wait_for_input "$1" "$2"' _ 'https://github.com/epilande/alfred-browser-tabs/releases/download/v1.0.7' 'Browser-Tabs.alfredworkflow'
debounce 90 d bash -c 'wait_for_input "$1" "$2"' _ 'https://github.com/gharlan/alfred-github-workflow/releases/download/v1.7.1' 'github.alfredworkflow'
debounce 90 d bash -c 'wait_for_input "$1" "$2"' _ 'https://github.com/jsumners/alfred-emoji/releases/download/v2.2.0' 'alfred-emoji.alfredworkflow'
debounce 90 d bash -c 'wait_for_input "$1" "$2"' _ 'https://github.com/mrodalgaard/alfred-network-workflow/releases/download/v1.1' 'Network.alfredworkflow'
debounce 90 d bash -c 'wait_for_input "$1" "$2"' _ 'https://github.com/packal/repository/raw/master/com.pawelgrzybek.div' 'div.alfredworkflow'
debounce 90 d bash -c 'wait_for_input "$1" "$2"' _ 'https://github.com/ruedap/alfred-font-awesome-workflow/releases/download/v5.15.3.1' 'Font-Awesome.alfredworkflow'

alfred_metacpan() {
    repo=alfred-metacpan-workflow
    rm -rf "$repo"
    git clone "git@github.com:oalders/$repo.git"
    cd "$repo" && mkdir -p dist && make
    # The Makefile names the artifact after `git describe`, so derive the file
    # name the same way instead of hardcoding a version that goes stale.
    version=$(git describe --tags --always --dirty)
    open "dist/metacpan-$version.alfredworkflow"
}
export -f alfred_metacpan

debounce 90 d bash -c 'alfred_metacpan'

exit 0

# See also:
# https://alfred.app/workflows/benziahamed/menu-bar-search/
# https://alfred.app/workflows/alfredapp/system-settings/
