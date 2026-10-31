#!/usr/bin/env bats

load 'helpers.bash'

@test "get_github_display_name strips a semicolon tmux would parse as a command separator" {
    FAKE_HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$FAKE_HOME"
    ln -s "$SCRIPT_DIR" "$FAKE_HOME/dot-files"
    setup_sandbox
    stub_command gh "echo '{\"title\":\"Admin org edit: two duplicate-orgs cards; keep JS one, add Edit link and linked website\",\"labels\":[]}'"

    run env -i HOME="$FAKE_HOME" PATH="$PATH" bash --norc --noprofile -c '
        . ~/dot-files/bash_functions.sh >/dev/null 2>&1
        get_github_display_name fix-4216'
    [ "$status" -eq 0 ]
    [ "$output" = "Admin org edit two duplicate-orgs cards keep" ]
}
