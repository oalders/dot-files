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

# #935: when @{u} fails but the branch IS on origin (only the local tracking
# config is wrong), don't misdiagnose it as "push first" — and don't prompt.
# The repair is self-healing: closed stdin stands in for a non-interactive run
# (cron, a pipe), where the old prompt aborted. Reaching PR lookup (which the
# gh stub fails) proves the pre-flight passed on the repaired tracking.
@test "pre-flight: misconfigured tracking self-heals instead of saying 'push first'" {
    setup_git_repo
    setup_upstream
    break_tracking_config
    stub_command gh 'exit 1'
    run "$MERGE_PR" </dev/null
    [ "$status" -eq 1 ]
    [[ "$output" != *"push first"* ]]
    [[ "$output" == *"is on origin"* ]]
    [[ "$output" == *"--set-upstream-to=origin/main"* ]]
    [[ "$output" == *"no PR found"* ]]
    [[ "$output" != *"[y/N]"* ]]
    [[ "$output" != *"aborted"* ]]
    run git config "branch.main.remote"
    [[ "$output" == "origin" ]]
}

# The branch is on origin but this clone has no refs/remotes/origin/<branch>
# (pushed from elsewhere, or the tracking ref was pruned). --set-upstream-to
# alone fails there with "the requested upstream branch does not exist", so
# the repair has to fetch the ref first.
@test "pre-flight: tracking repair works with no local remote-tracking ref" {
    setup_git_repo
    setup_upstream
    git checkout -q -b feature
    git push -q origin feature
    git branch -q -D -r origin/feature
    git config --unset branch.feature.remote || true
    git config --unset branch.feature.merge || true
    stub_command gh 'exit 1'
    run "$MERGE_PR" </dev/null
    # Reaching PR lookup (which the gh stub fails) proves the repair worked.
    [ "$status" -eq 1 ]
    [[ "$output" == *"no PR found"* ]]
    run git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    [ "$status" -eq 0 ]
    [[ "$output" == "origin/feature" ]]
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

# #1007: a stale refs/remotes/origin/<branch> made already-pushed commits look
# unpushed. Push a second commit (B) so origin and HEAD agree at B, then rewind
# the tracking ref to the earlier SHA (A) — exactly the phantom count. The
# pre-flight now refreshes the ref (offline, against the local bare origin)
# before counting, so it must NOT report "unpushed commit(s)" and must proceed
# past the pre-flight to the gh-stub PR-lookup failure.
@test "pre-flight: stale tracking ref does not block an already-pushed branch" {
    setup_git_repo
    setup_upstream
    local a
    a=$(git rev-parse HEAD)
    git -c commit.gpgsign=false commit -q --allow-empty -m "B"
    git push -q origin HEAD
    # Rewind the local tracking ref to A while origin/HEAD are both at B.
    git update-ref "refs/remotes/origin/main" "$a"
    stub_command gh 'exit 1'
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" != *"unpushed commit"* ]]
    [[ "$output" == *"no PR found"* ]]
}

# #1007: the refresh fetch is non-fatal. Point origin at a nonexistent repo so
# the fetch fails; under `set -e` a bare fetch would abort the script, but the
# guarded form must warn and continue past the pre-flight (reaching the gh-stub
# PR-lookup failure) rather than aborting.
@test "pre-flight: refresh fetch failure warns but is non-fatal" {
    setup_git_repo
    setup_upstream
    # Unreachable remote: @{u} still resolves locally, but the fetch fails.
    git remote set-url origin "$BATS_TEST_TMPDIR/nonexistent.git"
    stub_command gh 'exit 1'
    run "$MERGE_PR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"could not refresh 'origin/main'"* ]]
    [[ "$output" == *"no PR found"* ]]
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

# A worktree *of* a submodule lives under the superproject's
# .git/modules/<name>, so `git rev-parse --git-common-dir` points there.
# Teardown must resolve the submodule's own main working tree (via
# core.worktree), not `git_common_dir/..` (which is .git/modules — not a
# working tree at all), or `git worktree remove` aborts with "is not a
# working tree" and the worktree is stranded.
@test "cleanup: removes a clean worktree of a submodule" {
    setup_submodule_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "MERGED\tmain\n"'

    run "$MERGE_PR"
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$SUBMODULE_MAIN" branch --list feature
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

# `gh pr close` on a MERGED PR is nonsensical, but the teardown isn't: skip
# the close call, say so, and run full cleanup (mirrors the CLOSED test above
# and merge mode's already-MERGED path).
@test "close: --close on a MERGED PR skips close and still tears down" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "MERGED\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [[ "$output" == *"already MERGED — closing is a no-op"* ]]
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
}

# Extra pass-through args have no consumer on the MERGED path (there's no
# `gh pr close` call to take them); they must be ignored, not refused.
@test "close: --close on a MERGED PR ignores extra gh args" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "MERGED\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --close --comment "wontfix"
    [ "$status" -eq 0 ]
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
}

# #1020: close mode deletes origin/<branch> only when it holds no commits we
# lack. A branch name recreated on origin with commits HEAD never saw still
# resolves the old PR, so deleting it would drop those commits. The guard must
# warn, skip the delete, and still finish local teardown.
@test "close: --close leaves origin/<branch> alone when it has commits not in HEAD" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'
    # Recreate origin/feature at a commit HEAD does not contain, then rewind
    # HEAD back so origin is ahead of (and divergent from) the local branch.
    git -c commit.gpgsign=false commit -q --allow-empty -m "origin-only recreate"
    local recreated
    recreated="$(git rev-parse HEAD)"
    git push -q -f origin feature
    git reset -q --hard HEAD~1

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [[ "$output" == *"is not a known ancestor of HEAD"* ]]
    [ -e "$BATS_TEST_TMPDIR/close-was-called" ]
    # Local teardown still ran ...
    [ ! -d "$WORKTREE_DIR" ]
    # ... but the remote branch survives, untouched.
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [[ "$output" == "$recreated"$'\t'refs/heads/feature ]]
}

# #1020, exit-128 path: the real scenario is origin/<branch> carrying commits
# this clone never fetched, so `merge-base --is-ancestor` errors on the unknown
# object rather than returning "not an ancestor". A second clone pushes the
# foreign commit so it stays out of the main repo's object store. The guard
# must treat "can't resolve the object" the same as divergence: warn and skip.
@test "close: --close leaves origin/<branch> alone when its commits were never fetched" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'
    # Push a commit to origin/feature from a separate clone; the main repo never
    # fetches it, so its object is absent locally.
    git clone -q "$UPSTREAM_DIR" "$BATS_TEST_TMPDIR/other"
    git -C "$BATS_TEST_TMPDIR/other" config user.email "test@example.com"
    git -C "$BATS_TEST_TMPDIR/other" config user.name "Test"
    git -C "$BATS_TEST_TMPDIR/other" checkout -q feature
    git -C "$BATS_TEST_TMPDIR/other" -c commit.gpgsign=false commit -q --allow-empty -m "foreign commit"
    git -C "$BATS_TEST_TMPDIR/other" push -q origin feature
    local foreign
    foreign="$(git -C "$BATS_TEST_TMPDIR/other" rev-parse HEAD)"

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [[ "$output" == *"is not a known ancestor of HEAD"* ]]
    [ -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [[ "$output" == "$foreign"$'\t'refs/heads/feature ]]
}

# #1020: the guard is an ancestry test, not equality. Close mode tolerates
# unpushed local commits (local ahead of remote is normal), so a remote that is
# an ancestor of HEAD must still be deleted.
@test "close: --close still deletes origin/<branch> when local is ahead of remote" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'
    git -c commit.gpgsign=false commit -q --allow-empty -m "extra unpushed"

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [ -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -z "$output" ]
}

# delete_branch_on_merge normally removes the remote branch before we get
# here, making the close-mode delete a silent no-op. Simulate that repo by
# deleting origin/feature first: teardown must still exit 0 without warning.
@test "close: --close on a MERGED PR is silent when the remote branch is gone" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    git push -q origin --delete feature
    stub_command gh '
case "$2" in
    view) printf "MERGED\tmain\n" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    [[ "$output" != *"could not delete remote branch"* ]]
    [[ "$output" != *"warning"* ]]
    [ ! -d "$WORKTREE_DIR" ]
}

# With delete_branch_on_merge off the merged branch is still on origin; close
# mode's explicit delete is the cleanup --close promises, so it must run.
@test "close: --close on a MERGED PR deletes a lingering remote branch" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "MERGED\tmain\n" ;;
esac
'

    run "$MERGE_PR" --close
    [ "$status" -eq 0 ]
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -z "$output" ]
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
