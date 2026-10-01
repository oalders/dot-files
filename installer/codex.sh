#!/bin/bash

set -euxo pipefail

# shellcheck source=../bash_functions.sh
source ~/dot-files/bash_functions.sh

# Pin the Codex CLI so re-runs don't silently jump to latest. Bump here to
# upgrade. Codex ships as a platform-specific binary wrapped in an npm package;
# the global npm install is the arch-agnostic path (npm picks the right native
# binary), whereas ubi can't disambiguate the many similarly-named linux
# release assets (codex, codex-app-server, codex-responses-api-proxy, ...).
CODEX_VERSION=0.153.4

# Linux and macOS; npm (node) is installed earlier by npm.sh.
is os name eq linux || is os name eq darwin || exit 0
is there npm || exit 0

if is there codex && is cli version codex eq "$CODEX_VERSION"; then
    exit 0
fi

# A plain user-level global install: ~/.npmrc pins npm's prefix to
# ~/.npm-packages (a user-writable dir) on every platform, so no sudo needed.
npm install -g "@openai/codex@$CODEX_VERSION"
