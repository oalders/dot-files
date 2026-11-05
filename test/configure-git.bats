#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    stub_command is 'exit 1'
    FAKE_HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$FAKE_HOME/dot-files"
    cp -R "$SCRIPT_DIR/bash_functions.sh" "$SCRIPT_DIR/path_functions.sh" \
        "$SCRIPT_DIR/git" "$FAKE_HOME/dot-files/"
}

run_script() {
    # $TMPDIR may sit inside a checkout, so stop git discovering that repo.
    run env -i HOME="$FAKE_HOME" PATH="$PATH" GIT_CEILING_DIRECTORIES="$FAKE_HOME" \
        "$SCRIPT_DIR/configure/git.sh"
}

@test "skips hook setup when ~/dot-files is not a git repo" {
    run_script
    [ "$status" -eq 0 ]
}

@test "sets core.hooksPath once in a git checkout" {
    git init -q "$FAKE_HOME/dot-files"

    run_script
    [ "$status" -eq 0 ]
    [ "$(git -C "$FAKE_HOME/dot-files" config --local --get core.hooksPath)" = .githooks ]

    local before
    before=$(ls -i "$FAKE_HOME/dot-files/.git/config")
    run_script
    [ "$status" -eq 0 ]
    [ "$(ls -i "$FAKE_HOME/dot-files/.git/config")" = "$before" ]
}
