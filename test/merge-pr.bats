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

# #935: when @{u} fails but the branch IS on origin (only the local
# tracking config is wrong), don't misdiagnose it as "push first".
@test "pre-flight: misconfigured tracking is not reported as 'push first'" {
    setup_git_repo
    setup_upstream
    break_tracking_config
    run "$MERGE_PR" </dev/null
    [ "$status" -eq 1 ]
    [[ "$output" != *"push first"* ]]
    [[ "$output" == *"is on origin"* ]]
    [[ "$output" == *"--set-upstream-to=origin/main"* ]]
}

# Declining the repair prompt (empty input / no) leaves tracking untouched.
@test "pre-flight: declining the tracking-repair prompt aborts without changes" {
    setup_git_repo
    setup_upstream
    break_tracking_config
    run "$MERGE_PR" <<<"n"
    [ "$status" -eq 1 ]
    [[ "$output" == *"aborted"* ]]
    run git config "branch.main.remote"
    [[ "$output" == "$UPSTREAM_DIR" ]]
}

# Accepting the repair prompt rewrites tracking to origin and proceeds past
# the upstream pre-flight (then fails later at PR lookup — far enough to
# prove the repair worked).
@test "pre-flight: accepting the tracking-repair prompt sets upstream to origin" {
    setup_git_repo
    setup_upstream
    break_tracking_config
    stub_command gh 'exit 1'
    run "$MERGE_PR" <<<"y"
    # Repair succeeded, so the upstream pre-flight passed and we reached
    # PR lookup (which the gh stub fails).
    [ "$status" -eq 1 ]
    [[ "$output" == *"no PR found"* ]]
    run git config "branch.main.remote"
    [[ "$output" == "origin" ]]
}

# A genuinely unpushed branch whose name is a path suffix of an existing
# remote branch (e.g. local "foo" vs remote "feature/foo") must still get
# "push first", not the repair prompt. Guards against ls-remote tail-match.
@test "pre-flight: unpushed branch sharing a suffix with a remote branch says 'push first'" {
    setup_git_repo
    setup_upstream
    git checkout -q -b feature/foo
    git push -q -u origin feature/foo
    git checkout -q -b foo main
    run "$MERGE_PR" </dev/null
    [ "$status" -eq 1 ]
    [[ "$output" == *"push first"* ]]
    [[ "$output" != *"is on origin"* ]]
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

@test "pre-flight: refuses a dirty worktree without --force" {
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
@test "pre-flight: refuses a dirty submodule despite diff.ignoreSubmodules=all" {
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

@test "pre-flight: refuses a dirty submodule despite a per-submodule ignore=all" {
    _ready_repo
    setup_feature_worktree --with-submodule
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "MERGED\tmain\n"'
    git config submodule.sub.ignore all
    echo "dirty" >>sub/subfile

    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"uncommitted changes"* ]]
    [ -d "$WORKTREE_DIR" ]
}

# #940: a dirty worktree must bail *before* the merge runs, not after.
# The gh stub distinguishes `pr view` (state lookup) from `pr merge`
# (the actual merge), recording a marker file iff merge was invoked.
@test "pre-flight: dirty worktree bails before merging an OPEN PR" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
esac
'
    echo "dirty" >>file

    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"uncommitted changes"* ]]
    [ ! -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    [ -d "$WORKTREE_DIR" ]
}

@test "pre-flight: --force merges and cleans up a dirty worktree" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
esac
'
    echo "dirty" >>file

    run "$MERGE_PR" --force
    [ "$status" -eq 0 ]
    [ -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
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

# #950: --close tears down a PR without merging. The gh stub distinguishes
# `pr view` (state lookup) from `pr close`/`pr merge`, recording a marker
# file for whichever action runs. An OPEN PR must invoke `gh pr close`, never
# `gh pr merge`, then run the full teardown including remote-branch deletion.
@test "close: --close on an OPEN PR closes, cleans up, and deletes the remote branch" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [ -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
    # cwd was the now-removed worktree; ls-remote needs a valid cwd.
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -z "$output" ]
}

# An already-CLOSED PR skips the close call but still runs full teardown.
@test "close: --close on a CLOSED PR skips close and still tears down" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "CLOSED\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
    # cwd was the now-removed worktree; ls-remote needs a valid cwd.
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -z "$output" ]
}

# Close mode abandons the branch, so an unpushed commit must NOT bail the
# pre-flight (contrast the merge-mode "unpushed commits" test above).
@test "close: --close skips the unpushed-commit pre-flight" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    git -c commit.gpgsign=false commit -q --allow-empty -m "extra unpushed"
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [ -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
}

# Closing a MERGED PR is nonsensical; refuse it.
@test "close: --close on a MERGED PR refuses" {
    _ready_repo
    git checkout -q -b feature
    git push -q -u origin feature
    stub_command gh 'printf "MERGED\tmain\n"'

    run "$MERGE_PR" --close
    [ "$status" -eq 1 ]
    [[ "$output" == *"refusing to close a MERGED PR"* ]]
}

# Remote-branch deletion is tolerant: an already-gone branch still exits 0
# and completes local cleanup. Delete origin/feature before running.
@test "close: --close tolerates an already-deleted remote branch" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    git push -q origin --delete feature
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [ -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}

@test "close: usage mentions --close" {
    run "$MERGE_PR" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"--close"* ]]
}
