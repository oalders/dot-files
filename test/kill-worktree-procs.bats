#!/usr/bin/env bats

load 'helpers.bash'

# #1109: a session must never list its own processes as victims, including
# subshells spawned after startup. Dry-run only: a real run could signal the
# agent session running these tests.
@test "spares its own session, including children spawned mid-run" {
    [[ $(uname) == Linux ]] || skip "needs /proc (Linux only)"
    wt="$BATS_TEST_TMPDIR/wt"
    mkdir -p "$wt" "$BATS_TEST_TMPDIR/fake"
    # A bash named "claude" (/proc comm) gives a session root even outside one.
    fake_claude="$BATS_TEST_TMPDIR/fake/claude"
    ln -s "$(command -v bash)" "$fake_claude"
    export BIN_DIR wt
    cd "$wt"

    # "; exit" stops bash exec-ing the helper, which would drop the fake claude.
    run "$fake_claude" -c '"$BIN_DIR"/kill-worktree-procs --dry-run "$wt"; exit $?'
    [ "$status" -eq 0 ]
    [[ "$output" == *"all protected; nothing to kill"* ]]
}
