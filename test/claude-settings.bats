#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    CLAUDE_SETTINGS="$SCRIPT_DIR/configure/claude-settings.sh"
    # The script writes to $HOME/.claude/settings.json; sandbox HOME so it
    # never touches the real one.
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    SETTINGS="$HOME/.claude/settings.json"
}

@test "bakes attribution.sessionUrl=false into a fresh settings file" {
    run "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.attribution.sessionUrl' "$SETTINGS")" = "false" ]
}

@test "attribution write is idempotent (no re-set on second run)" {
    "$CLAUDE_SETTINGS" >/dev/null
    run "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -Fq 'set attribution.sessionUrl'
    [ "$(jq -r '.attribution.sessionUrl' "$SETTINGS")" = "false" ]
}

@test "merging preserves a user-set sibling under attribution" {
    mkdir -p "$(dirname "$SETTINGS")"
    echo '{"attribution":{"commit":"custom co-author"}}' >"$SETTINGS"
    run "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.attribution.sessionUrl' "$SETTINGS")" = "false" ]
    [ "$(jq -r '.attribution.commit' "$SETTINGS")" = "custom co-author" ]
}
