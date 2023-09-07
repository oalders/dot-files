#!/usr/bin/env bash

set -eux

cd /tmp

# Alfred won't let you add multiple workflows at once
wait_for_input() {
    url=$1
    file=$2
    rm -f "$2"

    curl --location -O "$url/$file"
    open "$file"

    read -n 1 -s -r -p "Press any key to continue"
}

wait_for_input 'https://github.com/alexchantastic/alfred-ip-address-workflow/releases/download/v1.0.3' 'alfred-ip-address-workflow.alfredworkflow'
wait_for_input 'https://github.com/epilande/alfred-browser-tabs/releases/download/v1.0.5' 'Browser-Tabs.alfredworkflow'
wait_for_input 'https://github.com/gharlan/alfred-github-workflow/releases/download/v1.7.1' 'github.alfredworkflow'
wait_for_input 'https://github.com/jsumners/alfred-emoji/releases/download/v1.12.0' 'alfred-emoji.alfredworkflow'
wait_for_input 'https://github.com/mrodalgaard/alfred-network-workflow/releases/download/v1.1' 'Network.alfredworkflow'
wait_for_input 'https://github.com/packal/repository/raw/master/com.pawelgrzybek.div' 'div.alfredworkflow'
wait_for_input 'https://github.com/ruedap/alfred-font-awesome-workflow/releases/download/v5.15.3.1' 'Font-Awesome.alfredworkflow'

repo=alfred-metacpan-workflow
rm -rf $repo
git clone "git@github.com:oalders/$repo.git"
cd $repo && mkdir -p dist && make && open dist/metacpan-0.0.5.alfredworkflow

exit 0

# See also:
# https://alfred.app/workflows/benziahamed/menu-bar-search/
# https://alfred.app/workflows/alfredapp/system-settings/
