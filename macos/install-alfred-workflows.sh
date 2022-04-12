#!/usr/bin/env bash

set -eux

cd /tmp

# Alfred won't let you add multiple workflows at once
wait_for_input() {
    URL=$1
    FILE=$2
    rm -f "$2"

    curl --location -O "$URL/$FILE"
    open "$FILE"

    read -n 1 -s -r -p "Press any key to continue"
}


wait_for_input 'https://github.com/alexchantastic/alfred-ip-address-workflow/releases/download/v1.0.3' 'alfred-ip-address-workflow.alfredworkflow'

# wait_for_input 'https://github.com/deanishe/alfred-vpn-manager/releases/download/v3.2.0' 'VPN-Manager-3.2.alfredworkflow'
# Temporarily switch to fork of alfred-vpn-manager. See https://github.com/deanishe/alfred-vpn-manager/pull/20
wait_for_input 'https://github.com/rombarcz/alfred-vpn-manager/releases/download/v3.3.0' 'VPN-Manager-3.3.alfredworkflow'

wait_for_input 'https://github.com/epilande/alfred-browser-tabs/releases/download/v1.0.5' 'Browser-Tabs.alfredworkflow'
wait_for_input 'https://github.com/gharlan/alfred-github-workflow/releases/download/v1.7.1' 'github.alfredworkflow'
wait_for_input 'https://github.com/jsumners/alfred-emoji/releases/download/v1.11.1' 'alfred-emoji.alfredworkflow'
wait_for_input 'https://github.com/mrodalgaard/alfred-network-workflow/releases/download/v1.1' 'Network.alfredworkflow'
wait_for_input 'https://github.com/ruedap/alfred-font-awesome-workflow/releases/download/v5.15.3.1' 'Font-Awesome.alfredworkflow'

REPO=alfred-metacpan-workflow
rm -rf $REPO
git clone "git@github.com:oalders/$REPO.git"
cd $REPO && mkdir -p dist && make && open dist/metacpan-0.0.5.alfredworkflow

exit 0
