#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    HOOK="$BIN_DIR/claude-hook-toolsmith"
}

# Feed a PreToolUse payload for a Bash call running $1 (extra jq fields in $2).
run_hook() {
    local extra="${2:-{\}}"
    run bash -c 'jq -n --arg cmd "$1" --argjson extra "$2" \
        "{hook_event_name: \"PreToolUse\", tool_name: \"Bash\", tool_input: {command: \$cmd}} + \$extra" \
        | "$3"' _ "$1" "$extra" "$HOOK"
}

denied() {
    [ "$status" -eq 0 ]
    [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = "deny" ]
}

allowed() {
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

six_line_heredoc() {
    printf '%s <<'"'"'EOF'"'"'\n' "$1"
    printf 'line%d\n' 1 2 3 4 5 6
    printf 'EOF'
}

@test "denies a long python3 heredoc" {
    run_hook "$(six_line_heredoc 'python3 -')"
    denied
    jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$output" | grep -Fq 'toolsmith:toolsmith'
}

@test "denies a long node -e block" {
    run_hook "$(printf "node -e '\n1\n2\n3\n4\n5\n6\n'")"
    denied
}

@test "denies a long perl heredoc after a cd" {
    run_hook "$(six_line_heredoc 'cd /x && perl')"
    denied
}

@test "allows a short python3 -c one-liner" {
    run_hook "python3 -c 'import sys; print(sys.version)'"
    allowed
}

@test "allows a five-line heredoc" {
    run_hook "$(printf "python3 - <<'EOF'\n1\n2\n3\n4\n5\nEOF")"
    allowed
}

@test "allows a long heredoc into cat" {
    run_hook "$(six_line_heredoc 'cat >notes.txt')"
    allowed
}

@test "allows running a saved script" {
    run_hook "python3 scripts/build.py --all"
    allowed
}

@test "ignores non-Bash tools" {
    run bash -c 'jq -n "{tool_name: \"Write\", tool_input: {content: \"x\"}}" | "$1"' _ "$HOOK"
    allowed
}

@test "exempts the toolsmith subagent" {
    run_hook "$(six_line_heredoc 'python3 -')" '{"agent_type":"toolsmith:toolsmith"}'
    allowed
}

@test "still denies other subagents" {
    run_hook "$(six_line_heredoc 'python3 -')" '{"agent_type":"general-purpose"}'
    denied
}
