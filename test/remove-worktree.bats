#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    REMOVE_WORKTREE="$BIN_DIR/remove-worktree"
    # No tmux: stub pgrep so the tmux-session-kill block is skipped (an empty
    # `$(pgrep tmux)` short-circuits it). Mirrors add-worktree.bats.
    stub_command pgrep 'exit 1'
    # Stub docker so the docker-teardown step is hermetic: every query returns
    # empty, so it finds no worktree-owned containers regardless of host state.
    stub_command docker 'exit 0'
    export GIT_CEILING_DIRECTORIES
    GIT_CEILING_DIRECTORIES="$(dirname "$BATS_TEST_TMPDIR")"
}

@test "remove-worktree prints usage with no args" {
    run "$REMOVE_WORKTREE"
    [[ "$output" == *"Usage: remove-worktree"* ]]
}

# Baseline: a plain worktree (no submodule) is removed without -f.
@test "remove-worktree removes a clean worktree without submodules" {
    setup_git_repo
    setup_upstream
    setup_feature_worktree
    # Run from the main repo, as a user would.
    cd "$REPO_DIR"

    run "$REMOVE_WORKTREE" feature
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}

# #977: a worktree containing an initialized submodule must be removed
# without the user passing -f. remove-worktree escalates to --force
# internally when .gitmodules is present; without that handling git refuses
# to remove a worktree with an active submodule and this fails.
@test "remove-worktree removes a worktree with a submodule without -f" {
    setup_git_repo
    setup_upstream
    setup_feature_worktree --with-submodule
    cd "$REPO_DIR"

    run "$REMOVE_WORKTREE" feature
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}
