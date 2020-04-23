#!/bin/bash

# Alfred won't let you add multiple workflows at once
wait_for_input() {
    read -n 1 -s -r -p "Press any key to continue"
}

cd /tmp

wget https://github.com/deanishe/alfred-vpn-manager/releases/download/v3.2.0/VPN-Manager-3.2.alfredworkflow
open VPN-Manager-3.2.alfredworkflow
wait_for_input

wget https://github.com/gharlan/alfred-github-workflow/releases/download/v1.6.2/github.alfredworkflow
open github.alfredworkflow
wait_for_input

wget https://github.com/alexchantastic/alfred-ip-address-workflow/releases/download/v1.0.3/alfred-ip-address-workflow.alfredworkflow
open alfred-ip-address-workflow.alfredworkflow
wait_for_input

wget https://github.com/handlename/alfred-metacpan-workflow/releases/download/0.0.4/metacpan-0.0.4.alfredworkflow
open metacpan-0.0.4.alfredworkflow
wait_for_input

wget https://github.com/mrodalgaard/alfred-network-workflow/releases/download/v1.1/Network.alfredworkflow
open Network.alfredworkflow
wait_for_input

wget https://github.com/fniephaus/alfred-travis-ci/releases/download/v2.1/Travis-CI-for-Alfred.alfredworkflow
open Travis-CI-for-Alfred.alfredworkflow
wait_for_input

wget https://github.com/ruedap/alfred-font-awesome-workflow/raw/master/Font-Awesome.alfredworkflow
open Font-Awesome.alfredworkflow

exit 0
