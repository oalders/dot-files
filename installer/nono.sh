#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

# Install the Claude Code pack and refresh installed nono packs from the signed
# registry. The nono *binary* is pinned separately in
# installer/ubi.sh and deliberately not touched here -- packs carry their own
# versioning and are upgraded via `nono update` / `nono outdated`.
is there nono || exit 0

# nolabs-ai replaced the always-further namespace, and `nono update` never
# crosses namespaces, so an old always-further/claude install must be removed
# by hand (`nono remove always-further/claude`) before this pull succeeds.
if ! nono list --installed | grep -q '^nolabs-ai/claude\b'; then
    nono pull nolabs-ai/claude
fi

nono update
