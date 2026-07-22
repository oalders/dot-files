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

# Like set_env_key, but for a top-level key whose value is raw JSON (bool,
# number, string, object) rather than a string env var.
set_key() {
    local key=$1 value=$2

    if jq -e --arg k "$key" --argjson v "$value" '.[$k] == $v' "$SETTINGS" >/dev/null; then
        return
    fi

    jq --arg k "$key" --argjson v "$value" '.[$k] = $v' "$SETTINGS" >"$SETTINGS.tmp"
    mv "$SETTINGS.tmp" "$SETTINGS"
    echo "set $key=$value in $SETTINGS"
}

# Pin the claude binary; installer/claude.sh owns which version we land on.
set_env_key DISABLE_AUTOUPDATER 1

# ...but keep plugins updating, which DISABLE_AUTOUPDATER would otherwise
# freeze alongside the CLI.
set_env_key FORCE_AUTOUPDATE_PLUGINS 1

# Compact automatically instead of needing a manual /compact. Compaction fires
# at window-33k (20k reserved for output, 13k buffer), and the window itself is
# clamped to the model max -- so on a 200k model anything above 200000 is a
# no-op, and anything below just compacts sooner for no saving. 200000 is the
# max useful value; it also keeps the clamp meaningful if 1M context is ever
# re-enabled above.
set_key autoCompactEnabled true
set_key autoCompactWindow 200000

# Stay on 200k-class context instead of the native 1M window some models (e.g.
# Sonnet 5) offer. Long context is rarely worth the spend here, and a hard
# ceiling keeps sessions focused. This is the setting that actually caps token
# spend -- autoCompactWindow above only moves when compaction fires.
set_env_key CLAUDE_CODE_DISABLE_1M_CONTEXT 1

# Cap concurrently-running subagents so one message can't fan out unbounded
# background agents. Added in claude 2.1.217, where it defaults to 20; inert on
# older versions. DISABLE_AUTOUPDATER above means installer/claude.sh decides
# when we actually land on a version that reads this.
set_env_key CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS 5
