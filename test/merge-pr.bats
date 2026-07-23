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
    # Stub docker so the docker-teardown step is hermetic: every query returns
    # empty, so it finds no worktree-owned containers regardless of host state.
    stub_command docker 'exit 0'
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

# A MERGED PR whose remote branch was auto-deleted (delete_branch_on_merge)
# has no resolvable upstream. Plain merge-pr must still tear it down — not bail
# "push first" — because `gh pr merge` never runs for a MERGED PR.
@test "cleanup: MERGED PR with no upstream tears down without 'push first'" {
    _ready_repo
    setup_feature_worktree
    # Simulate the auto-deleted remote branch: drop origin's ref (this also
    # removes the local origin/feature tracking ref, so `@{u}` no longer
    # resolves) and clear the tracking config for good measure.
    git -C "$REPO_DIR" push -q origin --delete feature
    git -C "$WORKTREE_DIR" branch --unset-upstream
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "MERGED\tmain\n"'

    run "$MERGE_PR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PR already MERGED"* ]]
    [[ "$output" != *"push first"* ]]
    [[ "$output" != *"has no upstream"* ]]
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

# #982: `gh pr close` has no implicit current-branch detection (its positional
# PR arg is required), so a bare `merge-pr --close` must pass the branch name
# explicitly. Without it, `gh pr close` errors and teardown never runs. The
# stub records its positional arg ($3, after `pr close`) so we can assert it.
@test "close: --close passes the branch name to gh pr close" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    close) printf "%s" "$3" >"$BATS_TEST_TMPDIR/close-arg" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [ "$(cat "$BATS_TEST_TMPDIR/close-arg")" = "feature" ]
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

# A branch that was NEVER pushed to origin must close and clean up silently:
# close mode skips the upstream pre-flight, and the remote-branch deletion is
# guarded by ls-remote, so the missing remote ref is normal — no warning.
@test "close: --close on a never-pushed branch is silent about the remote branch" {
    _ready_repo
    # Build the worktree by hand (unlike setup_feature_worktree, which pushes):
    # branch "feature" exists locally only, never on origin.
    WORKTREE_DIR="$BATS_TEST_TMPDIR/feature-wt"
    git worktree add -q "$WORKTREE_DIR" -b feature
    cd "$WORKTREE_DIR"
    git config user.email "test@example.com"
    git config user.name "Test"
    unset TMUX
    stub_command tmux 'exit 0'
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
    # The never-pushed path must not warn about a missing remote branch.
    # Check $output here, before the branch-list `run` clobbers it.
    [[ "$output" != *"could not delete remote branch"* ]]
    [[ "$output" != *"warning"* ]]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}

# #966: when merge-pr is run from the MAIN working tree (not a linked
# worktree), it must still merge and clean up the branch, but skip the
# worktree-removal step instead of emitting a `fatal:` + failure message.
# Build the scenario by checking out "feature" directly in the main repo
# (no `git worktree add`), so worktree_path == main_repo inside the script.
@test "main tree: merges, deletes branch, switches to base, skips worktree removal" {
    _ready_repo
    # _ready_repo leaves cwd in REPO_DIR; make that explicit so the test runs
    # from the main working tree (not a linked worktree) regardless of helper
    # changes.
    cd "$REPO_DIR"
    git checkout -q -b feature
    git push -q -u origin feature
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
esac
'

    run "$MERGE_PR"
    [ "$status" -eq 0 ]
    [ -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    # No worktree-removal attempt: no fatal, no failure message.
    [[ "$output" != *"fatal"* ]]
    [[ "$output" != *"failed to remove worktree"* ]]
    [[ "$output" == *"main working tree"* ]]
    # The main checkout still exists, the branch is gone, and HEAD is on base.
    [ -d "$REPO_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
    run git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD
    [[ "$output" == "main" ]]
}

# Main-tree + --close: closes the PR, deletes the remote branch, and cleans up
# locally without attempting (and failing) to remove the main working tree.
@test "main tree: --close cleans up and deletes the remote branch, no worktree removal" {
    _ready_repo
    cd "$REPO_DIR"
    git checkout -q -b feature
    git push -q -u origin feature
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
    [[ "$output" != *"fatal"* ]]
    [ -d "$REPO_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
    # cwd is still REPO_DIR (the main tree is never removed), so ls-remote
    # against the upstream resolves fine without a cd.
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -z "$output" ]
}

# The exact #966 scenario: `gh pr merge -d` already switched to base and
# deleted the local branch before merge-pr's cleanup runs. The main-tree
# path must tolerate the already-gone branch and still exit 0 cleanly.
@test "main tree: tolerates a branch already switched-off and deleted by gh -d" {
    _ready_repo
    cd "$REPO_DIR"
    git checkout -q -b feature
    git push -q -u origin feature
    unset TMUX
    stub_command tmux 'exit 0'
    # Mimic `gh pr merge -d`: on merge, switch to main and delete the branch,
    # exactly as gh's --delete-branch would, before merge-pr cleans up.
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    merge) git switch -q main && git branch -D feature ;;
esac
'

    run "$MERGE_PR"
    [ "$status" -eq 0 ]
    [[ "$output" != *"fatal"* ]]
    [[ "$output" != *"failed to remove worktree"* ]]
    [ -d "$REPO_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}

# Main tree, switch failure: if the PR base has no local branch and no
# origin/<base> for git to DWIM from, the post-merge `git switch` fails. The
# script must report it clearly and exit non-zero rather than aborting with a
# bare git error — and must leave the (already-merged) branch in place.
@test "main tree: reports cleanly when it cannot switch off the branch to the base" {
    _ready_repo
    cd "$REPO_DIR"
    git checkout -q -b feature
    git push -q -u origin feature
    unset TMUX
    stub_command tmux 'exit 0'
    # Base "ghost" exists neither locally nor on origin, so `git switch ghost`
    # cannot succeed.
    stub_command gh '
case "$2" in
    view) printf "OPEN\tghost\n" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
esac
'

    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [ -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    [[ "$output" == *"could not switch off 'feature' to base 'ghost'"* ]]
    # The branch survives (left for manual cleanup); main tree intact.
    [ -d "$REPO_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [[ "$output" == *"feature"* ]]
}

# --close with no PR at all (gh pr view fails) must still tear down the
# worktree, local branch, and tmux session — the branch is being abandoned,
# and a missing PR just means there's nothing to close. Contrast the
# merge-mode "no PR found" test above, which exits 1.
@test "close: --close with no PR still tears down the worktree" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) exit 1 ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [[ "$output" == *"no PR found"* ]]
    [[ "$output" == *"proceeding to cleanup"* ]]
    # No PR means nothing to close: `gh pr close` must not run.
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}

# --close with no PR from the MAIN working tree: there's no linked worktree or
# tmux session to tear down, and deleting the checked-out branch would need a
# base we don't have. Report cleanly and leave the branch — never attempt (and
# fail) to remove the main working tree.
@test "main tree: --close with no PR reports nothing to tear down and leaves the branch" {
    _ready_repo
    cd "$REPO_DIR"
    git checkout -q -b feature
    git push -q -u origin feature
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) exit 1 ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [[ "$output" != *"fatal"* ]]
    [[ "$output" != *"failed to remove worktree"* ]]
    [[ "$output" == *"nothing to tear down"* ]]
    [ -d "$REPO_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [[ "$output" == *"feature"* ]]
}

@test "close: usage mentions --close" {
    run "$MERGE_PR" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"--close"* ]]
}
