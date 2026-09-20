#!/bin/bash

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

# I don't use Spotlight; its indexer (mds/mdworker/corespotlightd) grinds the
# disk, especially after big Homebrew source builds churn the Cellar. mdutil -i
# off is Apple's supported, reboot-persistent way to disable indexing. An OS
# update can silently re-enable it, so re-assert on every run -- but only sudo
# when something is still enabled, to avoid a needless password prompt.
is os name eq darwin || exit 0

if mdutil -a -s 2>/dev/null | grep -q 'Indexing enabled'; then
    sudo mdutil -a -i off
fi
