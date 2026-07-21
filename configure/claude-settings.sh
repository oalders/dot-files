#!/usr/bin/env bash

# Force host-level Claude Code settings that must not live in this repo.
# ~/.claude/settings.json is deliberately untracked (it holds the plugin list
# and marketplace config), so we merge individual keys into whatever is
# already there rather than symlinking or overwriting the file.
#
# bin/nn sets the same env vars for nono-sandboxed sessions. Setting them here
# covers plain `claude` runs, which never go through bin/nn.

set -eu -o pipefail

SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$(dirname "$SETTINGS")"

if [[ ! -f $SETTINGS ]]; then
    echo '{}' >"$SETTINGS"
fi

set_env_key() {
    local key=$1 value=$2

    if jq -e --arg k "$key" --arg v "$value" '.env[$k] == $v' "$SETTINGS" >/dev/null; then
        return
    fi

    jq --arg k "$key" --arg v "$value" '.env[$k] = $v' "$SETTINGS" >"$SETTINGS.tmp"
    mv "$SETTINGS.tmp" "$SETTINGS"
    echo "set env.$key=$value in $SETTINGS"
}

# Pin the claude binary; installer/claude.sh owns which version we land on.
set_env_key DISABLE_AUTOUPDATER 1

# ...but keep plugins updating, which DISABLE_AUTOUPDATER would otherwise
# freeze alongside the CLI.
set_env_key FORCE_AUTOUPDATE_PLUGINS 1
