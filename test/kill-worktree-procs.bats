#!/usr/bin/env bats

load 'helpers.bash'

# #1109: a session must never list its own processes as victims, including
# subshells spawned after startup. Dry-run only: a real run could signal the
# agent session running these tests.
@test "spares its own session, including children spawned mid-run" {
    wt="$BATS_TEST_TMPDIR/wt"
    mkdir -p "$wt" "$BATS_TEST_TMPDIR/fake"
    # A bash named `claude` makes this test its own session root (/proc comm).
    fake_claude="$BATS_TEST_TMPDIR/fake/claude"
    ln -s "$(command -v bash)" "$fake_claude"
    export BIN_DIR wt
    cd "$wt"

    run "$fake_claude" -c '"$BIN_DIR"/kill-worktree-procs --dry-run "$wt"'
    [ "$status" -eq 0 ]
    [[ "$output" == *"all protected; nothing to kill"* ]]
}
