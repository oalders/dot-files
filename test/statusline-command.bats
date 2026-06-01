#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    STATUSLINE="$SCRIPT_DIR/claude/statusline-command.sh"
}

# Assertions strip ANSI escape sequences (sed) so they match on visible
# text only — the statusline emits Tokyo Night truecolor codes.

@test "context-bar branch renders truncated session id" {
    json='{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/home/u/proj"},"context_window":{"used_percentage":40},"session_id":"abcd1234-5678-90ab-cdef-1234567890ab"}'
    run bash -c "printf '%s' '$json' | '$STATUSLINE' | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    echo "$output" | grep -Fq 'session:'
    echo "$output" | grep -Fq 'abcd1234'
    # Truncated: the full UUID tail must not appear.
    ! echo "$output" | grep -Fq 'abcd1234-5678'
}

@test "no-context branch renders truncated session id" {
    json='{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/home/u/proj"},"session_id":"abcd1234-5678-90ab-cdef-1234567890ab"}'
    run bash -c "printf '%s' '$json' | '$STATUSLINE' | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    echo "$output" | grep -Fq 'session:'
    echo "$output" | grep -Fq 'abcd1234'
    echo "$output" | grep -Fq 'proj'
}

@test "no session segment when session_id absent (context-bar branch)" {
    json='{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/home/u/proj"},"context_window":{"used_percentage":40}}'
    run bash -c "printf '%s' '$json' | '$STATUSLINE' | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -Fq 'session:'
    # Still renders model and folder cleanly, no dangling trailing separator.
    echo "$output" | grep -Fq 'Opus'
    echo "$output" | grep -Fq 'proj'
    ! echo "$output" | grep -Eq '\|[[:space:]]*$'
}

@test "no session segment when session_id absent (no-context branch)" {
    json='{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/home/u/proj"}}'
    run bash -c "printf '%s' '$json' | '$STATUSLINE' | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -Fq 'session:'
    echo "$output" | grep -Fq 'Opus'
    echo "$output" | grep -Fq 'proj'
    ! echo "$output" | grep -Eq '\|[[:space:]]*$'
}
