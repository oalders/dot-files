#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    MERGE_PR="$BIN_DIR/merge-pr"
}

@test "merge-pr -h prints usage and exits 0" {
    run "$MERGE_PR" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: merge-pr"* ]]
}

@test "merge-pr --help prints usage and exits 0" {
    run "$MERGE_PR" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: merge-pr"* ]]
}

@test "merge-pr --auto refuses with exit 2" {
    run "$MERGE_PR" --auto
    [ "$status" -eq 2 ]
    [[ "$output" == *"refusing --auto"* ]]
}

@test "merge-pr --auto-merge refuses with exit 2" {
    run "$MERGE_PR" --auto-merge
    [ "$status" -eq 2 ]
    [[ "$output" == *"refusing --auto-merge"* ]]
}

@test "merge-pr --auto refuses even when -f is also given" {
    run "$MERGE_PR" -f --auto
    [ "$status" -eq 2 ]
    [[ "$output" == *"refusing --auto"* ]]
}

@test "pre-flight: refuses when not in a git work tree" {
    cd "$BATS_TEST_TMPDIR"
    # Stop git from walking up into a parent repo (relevant when TMPDIR
    # itself lives inside a git work tree, e.g. some sandboxed CI envs).
    # Ceiling must be a strict ancestor of CWD, so use the tmpdir's parent.
    GIT_CEILING_DIRECTORIES="$(dirname "$BATS_TEST_TMPDIR")" run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not inside a git work tree"* ]]
}

@test "pre-flight: refuses when branch has no upstream" {
    setup_git_repo
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"has no upstream"* ]]
}

@test "pre-flight: refuses when branch has unpushed commits" {
    setup_git_repo
    setup_upstream
    git -c commit.gpgsign=false commit -q --allow-empty -m "extra"
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"unpushed commit"* ]]
}
