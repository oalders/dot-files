#!/usr/bin/env bash

set -eux

cd /tmp

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# Alfred won't let you add multiple workflows at once
# shellcheck disable=SC2317
wait_for_input() {
    url=$1
    file=$2
    rm -f "$2"

    curl --location -O "$url/$file"
    open "$file"

    read -n 1 -s -r -p "Press any key to continue"
}

debounce 90 d wait_for_input 'https://alfred.app/workflows/rknightuk/http-status-codes/download/' 'http-status-codes.alfredworkflow'
debounce 90 d wait_for_input 'https://github.com/alexchantastic/alfred-ip-address-workflow/releases/download/v1.0.3' 'alfred-ip-address-workflow.alfredworkflow'
debounce 90 d wait_for_input 'https://github.com/epilande/alfred-browser-tabs/releases/download/v1.0.7' 'Browser-Tabs.alfredworkflow'
debounce 90 d wait_for_input 'https://github.com/gharlan/alfred-github-workflow/releases/download/v1.7.1' 'github.alfredworkflow'
debounce 90 d wait_for_input 'https://github.com/jsumners/alfred-emoji/releases/download/v2.2.0' 'alfred-emoji.alfredworkflow'
debounce 90 d wait_for_input 'https://github.com/mrodalgaard/alfred-network-workflow/releases/download/v1.1' 'Network.alfredworkflow'
debounce 90 d wait_for_input 'https://github.com/packal/repository/raw/master/com.pawelgrzybek.div' 'div.alfredworkflow'
debounce 90 d wait_for_input 'https://github.com/ruedap/alfred-font-awesome-workflow/releases/download/v5.15.3.1' 'Font-Awesome.alfredworkflow'

# shellcheck disable=SC2317
alfred_metacpan() {
    repo=alfred-metacpan-workflow
    rm -rf "$repo"
    git clone "git@github.com:oalders/$repo.git"
    cd "$repo" && mkdir -p dist && make && open dist/metacpan-0.0.5.alfredworkflow
}

debounce 90 d alfred_metacpan

exit 0

# See also:
# https://alfred.app/workflows/benziahamed/menu-bar-search/
# https://alfred.app/workflows/alfredapp/system-settings/
