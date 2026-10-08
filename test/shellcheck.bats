#!/usr/bin/env bats

load 'helpers.bash'

@test "precious shellcheck passes on every shell script" {
    cd "$SCRIPT_DIR"
    run precious lint --all --command shellcheck
    [ "$status" -eq 0 ] || {
        printf '%s\n' "$output"
        false
    }
}
