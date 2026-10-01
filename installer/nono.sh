#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

# Refresh installed nono packs (e.g. the Claude Code pack always-further/claude)
# from the signed registry. The nono *binary* is pinned separately in
# installer/ubi.sh and deliberately not touched here -- packs carry their own
# versioning and are upgraded via `nono update` / `nono outdated`.
is there nono || exit 0

nono update
