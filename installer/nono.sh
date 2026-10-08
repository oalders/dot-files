#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# Install the Claude Code pack and refresh installed nono packs from the signed
# registry. The nono *binary* is pinned separately in
# installer/ubi.sh and deliberately not touched here -- packs carry their own
# versioning and are upgraded via `nono update` / `nono outdated`.
is there nono || exit 0

# nolabs-ai replaced the always-further namespace and `nono update` never
# crosses namespaces. The old pack is broken under nono >= 0.77 and `nono pull`
# refuses to overwrite its files, so remove it before pulling the new one.
has_pack() {
    nono list --installed | awk -F'\t' -v p="$1" '$1 == p { f = 1 } END { exit !f }'
}

if has_pack always-further/claude; then
    nono remove always-further/claude
fi

if ! has_pack nolabs-ai/claude; then
    nono pull nolabs-ai/claude
fi

nono update
