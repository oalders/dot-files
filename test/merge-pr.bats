#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    MERGE_PR="$BIN_DIR/merge-pr"
    # Stop git from walking past BATS_TEST_TMPDIR's parent. Without
    # this, when the developer's TMPDIR sits inside a git repo, tests
    # that expect "no surrounding repo" silently inherit the outer
    # one. See test "pre-flight: refuses when not in a git work tree".
    export GIT_CEILING_DIRECTORIES
    GIT_CEILING_DIRECTORIES="$(dirname "$BATS_TEST_TMPDIR")"
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
    run "$MERGE_PR"
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

@test "pre-flight: refuses on detached HEAD" {
    setup_git_repo
    setup_upstream
    git checkout -q --detach HEAD
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"detached HEAD"* ]]
}

# Helper: set up a git repo with upstream so pre-flight passes.
_ready_repo() {
    setup_git_repo
    setup_upstream
}

@test "pr lookup: refuses when gh pr view fails" {
    _ready_repo
    stub_command gh 'exit 1'
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no PR found for branch 'main'"* ]]
}

@test "pr lookup: refuses when current branch is the PR's base" {
    _ready_repo
    stub_command gh 'printf "OPEN\tmain\n"'
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"refusing to merge from base branch 'main'"* ]]
}

@test "pr state: refuses CLOSED state" {
    _ready_repo
    git checkout -q -b feature
    git push -q -u origin feature
    stub_command gh 'printf "CLOSED\tmain\n"'
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"refusing to act on PR in state 'CLOSED'"* ]]
}

@test "pr state: refuses DRAFT state" {
    _ready_repo
    git checkout -q -b feature
    git push -q -u origin feature
    stub_command gh 'printf "DRAFT\tmain\n"'
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"refusing to act on PR in state 'DRAFT'"* ]]
}

# Cleanup path. A MERGED PR skips the actual merge and goes straight to
# worktree removal. tmux is stubbed inert so session resolution (which
# runs under `set -e`) doesn't abort the script.
@test "cleanup: removes a clean worktree containing a submodule" {
    _ready_repo
    setup_feature_worktree --with-submodule
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "MERGED\tmain\n"'

    run "$MERGE_PR"
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}

@test "cleanup: removes a clean worktree without submodules" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "MERGED\tmain\n"'

    run "$MERGE_PR"
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}

@test "cleanup: refuses a dirty worktree without --force" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "MERGED\tmain\n"'
    echo "dirty" >>file

    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"uncommitted changes"* ]]
    [ -d "$WORKTREE_DIR" ]
}

# Uncommitted work inside a submodule must count as dirty, even when the
# repo configures diff.ignoreSubmodules to hide it from a plain status.
@test "cleanup: refuses a dirty submodule despite diff.ignoreSubmodules=all" {
    _ready_repo
    setup_feature_worktree --with-submodule
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "MERGED\tmain\n"'
    git config diff.ignoreSubmodules all
    echo "dirty" >>sub/subfile

    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"uncommitted changes"* ]]
    [ -d "$WORKTREE_DIR" ]
}

@test "cleanup: --force removes a worktree with a dirty submodule" {
    _ready_repo
    setup_feature_worktree --with-submodule
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "MERGED\tmain\n"'
    echo "dirty" >>sub/subfile

    run "$MERGE_PR" --force
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
}
