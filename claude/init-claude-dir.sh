#!/usr/bin/env bash
# Ensure required settings are present in /home/agent/.claude/settings.json.
# Called at container start before any Claude commands.
# The named volume mounts over /home/agent/.claude, so baked-in image
# settings may already exist from plugin installation. This script merges
# our required keys into whatever settings.json is already there.

set -euo pipefail

CLAUDE_DIR="/home/agent/.claude"
BAKED_DIR="/home/agent/dot-files/claude"
SETTINGS="${CLAUDE_DIR}/settings.json"

mkdir -p "${CLAUDE_DIR}"

if [[ ! -f "${SETTINGS}" ]]; then
    # First run: copy baked-in settings wholesale
    cp "${BAKED_DIR}/settings.json" "${SETTINGS}"
    echo "Initialized ${SETTINGS} from image defaults"
else
    # Merge required keys into existing settings
    # Add skipDangerousModePermissionPrompt if missing
    if ! jq -e '.skipDangerousModePermissionPrompt' "${SETTINGS}" >/dev/null 2>&1; then
        jq '.skipDangerousModePermissionPrompt = true' "${SETTINGS}" > "${SETTINGS}.tmp" \
            && mv "${SETTINGS}.tmp" "${SETTINGS}"
        echo "Added skipDangerousModePermissionPrompt to ${SETTINGS}"
    fi
fi
