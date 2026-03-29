#!/usr/bin/env bash
# Initialize /home/agent/.claude from baked-in defaults if empty.
# Called at container start before any Claude commands.
# The named volume mounts over /home/agent/.claude, so baked-in files
# are shadowed. This script copies them into the volume on first run.

set -euo pipefail

CLAUDE_DIR="/home/agent/.claude"
BAKED_DIR="/home/agent/dot-files/claude"

# Only copy if settings.json doesn't exist yet (first run)
if [[ ! -f "${CLAUDE_DIR}/settings.json" ]]; then
    mkdir -p "${CLAUDE_DIR}"
    cp "${BAKED_DIR}/settings.json" "${CLAUDE_DIR}/settings.json"
    echo "Initialized ${CLAUDE_DIR}/settings.json from image defaults"
fi
