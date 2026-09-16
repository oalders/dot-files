# merge-pr `--punt` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `--punt` mode to `bin/merge-pr` that tears down the worktree, local branch, and tmux session while leaving the PR OPEN and `origin/<branch>` intact, so the work can be revisited later.

**Architecture:** `--punt` reuses the entire existing teardown path. It only (1) parses a new flag and refuses combining it with `--close` via a post-loop check, and (2) skips the merge/close dispatch with a state-aware informational line. The unpushed-commits guard and remote-branch preservation are inherited for free from the existing `close_mode` gating; requiring a PR and enforcing the guard on OPEN are inherited from the existing `gh pr view` failure branch and the `pr_state == OPEN` resolution.

**Tech Stack:** Bash (`set -eu -o pipefail`), bats tests with command stubs (`test/helpers.bash`).

## Global Constraints

- Script header is `set -eu -o pipefail`; every new read of a variable must be safe under `set -u` (initialize `punt_mode=""` unconditionally, like `force`/`close_mode`).
- Shell style: `shfmt -w -s -i 4` (4-space indent); the file must pass `precious lint`.
- Comments: minimal, explain the non-obvious *why* (per CLAUDE.md). The post-loop mutual-exclusion placement and the state-aware line each warrant one load-bearing sentence.
- Do not forward `--punt` to `gh` (consume it in the arg loop, like `--close`/`-f`).
- Spec of record: `docs/superpowers/specs/2026-09-16-merge-pr-punt-teardown-design.md`.

---

### Task 1: Add `--punt` mode to `bin/merge-pr` with tests

**Files:**
- Modify: `bin/merge-pr` (arg parsing ~40-63; PR-state dispatch ~264-304; usage heredoc ~5-35)
- Test: `test/merge-pr.bats` (append new `@test` blocks)

**Interfaces:**
- Consumes: existing helpers `setup_git_repo`, `setup_upstream`, `_ready_repo`, `setup_feature_worktree`, `stub_command`; variables `WORKTREE_DIR`, `REPO_DIR`, `UPSTREAM_DIR`, `MERGE_PR`.
- Produces: `merge-pr --punt` behavior; new exit code 2 for `--punt`+`--close`; usage text mentioning `--punt`.

- [ ] **Step 1: Write the failing tests**

Append these `@test` blocks to the end of `test/merge-pr.bats`:

```bash
# --punt tears down the worktree but leaves the PR OPEN and origin/<branch>
# in place, for revisiting later. Distinct from --close: no gh action, no
# remote-branch delete.
@test "punt: --punt on an OPEN PR tears down but leaves PR and remote branch" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --punt
    [ "$status" -eq 0 ]
    [[ "$output" == *"leaving PR OPEN (--punt)"* ]]
    [ ! -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -n "$output" ]
}

# --punt discards local state, so revisitable work must be on origin first:
# an unpushed commit blocks teardown (contrast --close, which skips this).
@test "punt: --punt refuses on unpushed commits" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    git -c commit.gpgsign=false commit -q --allow-empty -m "extra unpushed"
    stub_command gh 'printf "OPEN\tmain\n"'

    run "$MERGE_PR" --punt
    [ "$status" -eq 1 ]
    [[ "$output" == *"unpushed commit"* ]]
    [ -d "$WORKTREE_DIR" ]
}

# --punt and --close are mutually exclusive terminal modes. The refusal is a
# POST-LOOP check, so it catches both orderings; if it didn't, the remote-delete
# block (gated on close_mode alone) would delete origin/<branch> — the exact
# thing --punt promises to keep. Assert the remote survives.
@test "punt: --punt with --close refuses (both orders) and touches nothing" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh ': >"$BATS_TEST_TMPDIR/gh-was-called"'

    run "$MERGE_PR" --punt --close
    [ "$status" -eq 2 ]
    [[ "$output" == *"mutually exclusive"* ]]

    run "$MERGE_PR" --close --punt
    [ "$status" -eq 2 ]
    [[ "$output" == *"mutually exclusive"* ]]

    [ ! -e "$BATS_TEST_TMPDIR/gh-was-called" ]
    [ -d "$WORKTREE_DIR" ]
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -n "$output" ]
}

# --force still discards a dirty worktree during punt teardown (same as merge
# mode); the PR is still not acted on.
@test "punt: --punt --force tears down a dirty worktree, PR untouched" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'
    echo "dirty" >>file

    run "$MERGE_PR" --punt --force
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
    [ ! -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
}

# --punt's premise is an OPEN PR to leave open. With no PR it exits 1 (the
# differentiator from --close, which proceeds on no PR).
@test "punt: --punt refuses when no PR exists" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'exit 1'

    run "$MERGE_PR" --punt
    [ "$status" -eq 1 ]
    [[ "$output" == *"no PR found"* ]]
    [ -d "$WORKTREE_DIR" ]
}

# On a MERGED PR --punt does not act on the PR (already terminal); it degrades
# to plain teardown, does not delete the remote branch, and its info line says
# "untouched", not "OPEN".
@test "punt: --punt on a MERGED PR tears down and leaves the remote branch" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "MERGED\tmain\n" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --punt
    [ "$status" -eq 0 ]
    [[ "$output" == *"untouched"* ]]
    [[ "$output" != *"leaving PR OPEN"* ]]
    [ ! -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [ ! -d "$WORKTREE_DIR" ]
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -n "$output" ]
}

# On a CLOSED PR --punt likewise tears down without acting, leaving the remote.
@test "punt: --punt on a CLOSED PR tears down and leaves the remote branch" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "CLOSED\tmain\n"'

    run "$MERGE_PR" --punt
    [ "$status" -eq 0 ]
    [[ "$output" == *"untouched"* ]]
    [ ! -d "$WORKTREE_DIR" ]
    cd "$REPO_DIR"
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -n "$output" ]
}

# The base-branch refusal still applies to --punt (tearing down the base
# branch's own worktree is nonsensical).
@test "punt: --punt refuses on the base branch" {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh 'printf "OPEN\tfeature\n"'

    run "$MERGE_PR" --punt
    [ "$status" -eq 1 ]
    [[ "$output" == *"refusing to merge from base branch 'feature'"* ]]
    [ -d "$WORKTREE_DIR" ]
}

# From the MAIN working tree (not a linked worktree), --punt switches to base,
# deletes the local branch, and skips worktree removal — while leaving the PR
# and origin/<branch> in place.
@test "punt: --punt from the main working tree deletes branch, keeps PR and remote" {
    _ready_repo
    cd "$REPO_DIR"
    git checkout -q -b feature
    git push -q -u origin feature
    unset TMUX
    stub_command tmux 'exit 0'
    stub_command gh '
case "$2" in
    view) printf "OPEN\tmain\n" ;;
    merge) : >"$BATS_TEST_TMPDIR/merge-was-called" ;;
    close) : >"$BATS_TEST_TMPDIR/close-was-called" ;;
esac
'

    run "$MERGE_PR" --punt
    [ "$status" -eq 0 ]
    [ ! -e "$BATS_TEST_TMPDIR/merge-was-called" ]
    [ ! -e "$BATS_TEST_TMPDIR/close-was-called" ]
    [[ "$output" != *"fatal"* ]]
    [[ "$output" == *"main working tree"* ]]
    [ -d "$REPO_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -z "$output" ]
    run git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD
    [[ "$output" == "main" ]]
    run git ls-remote "$UPSTREAM_DIR" refs/heads/feature
    [ -n "$output" ]
}

@test "punt: usage mentions --punt" {
    run "$MERGE_PR" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"--punt"* ]]
}
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run: `bats test/merge-pr.bats -f punt`
Expected: FAIL. `--punt` is currently an unknown arg forwarded to `gh` (or treated as a merge), so `leaving PR OPEN`/`untouched`/`mutually exclusive` never appear and status codes differ from asserted.

- [ ] **Step 3: Add `punt_mode` parsing and the post-loop mutual-exclusion check**

In `bin/merge-pr`, initialize `punt_mode` alongside the other flags:

```bash
force=""
close_mode=""
punt_mode=""
gh_args=()
```

Add a `--punt` arm to the arg-loop `case` (next to `--close`):

```bash
        --close)
            close_mode="1"
            ;;
        --punt)
            punt_mode="1"
            ;;
```

Immediately after the `for` loop closes (`done`), before the "must be inside a git work tree" pre-flight, add:

```bash
# Post-loop, not an in-loop arm: the loop sets close_mode/punt_mode one at a
# time in argument order, so neither arm can see the other flag reliably. If
# both survived, the remote-delete block (gated on close_mode alone) would
# delete origin/<branch> — exactly what --punt promises to keep.
if [[ -n "$punt_mode" && -n "$close_mode" ]]; then
    echo "merge-pr: refusing --punt with --close — they are mutually exclusive" >&2
    exit 2
fi
```

- [ ] **Step 4: Skip the merge/close dispatch for punt mode**

Replace the dispatch block that begins `if [[ -z "$no_pr" ]]; then` (currently wrapping the `case "$pr_state" in` … `esac`) with a punt-aware version. `--punt` never invokes `gh`; the base-branch refusal above still applies because it runs before this block:

```bash
if [[ -z "$no_pr" ]]; then
    if [[ -n "$punt_mode" ]]; then
        # --punt leaves the PR untouched in every state. State-aware wording so
        # we never assert "OPEN" for a MERGED/CLOSED PR.
        if [[ "$pr_state" == "OPEN" ]]; then
            echo "merge-pr: leaving PR OPEN (--punt) — proceeding to cleanup"
        else
            echo "merge-pr: leaving PR ($pr_state) untouched (--punt) — proceeding to cleanup"
        fi
    else
        case "$pr_state" in
            OPEN)
                if [[ -n "$close_mode" ]]; then
                    gh pr close "$branch" "${gh_args[@]}"
                else
                    gh pr merge "${gh_args[@]}"
                fi
                ;;
            MERGED)
                if [[ -n "$close_mode" ]]; then
                    echo "merge-pr: PR already MERGED — closing is a no-op, proceeding to cleanup"
                else
                    echo "merge-pr: PR already MERGED — proceeding to cleanup"
                fi
                ;;
            CLOSED)
                if [[ -n "$close_mode" ]]; then
                    echo "merge-pr: PR already CLOSED — proceeding to cleanup"
                else
                    echo "merge-pr: refusing to act on PR in state '$pr_state'" >&2
                    exit 1
                fi
                ;;
            *)
                echo "merge-pr: refusing to act on PR in state '$pr_state'" >&2
                exit 1
                ;;
        esac
    fi
fi
```

(Only the outer `if [[ -n "$punt_mode" ]] … else … fi` wrapper is new; the existing `case` body is preserved verbatim inside the `else`, keeping its comments.)

- [ ] **Step 5: Update the usage text**

In the `usage()` heredoc, add `[--punt]` to the `Usage:` line:

```
Usage: merge-pr [-f|--force] [--close] [--punt] [gh pr merge/close args...]
```

Add a `--punt` entry under `Options:` after the `--close` block:

```
  --punt        Tear down the worktree, local branch, and tmux session but
                leave the PR OPEN and the remote branch in place, so the work
                can be revisited later (re-create a worktree from
                origin/<branch>). Does not run `gh pr merge`/`gh pr close`.
                Unlike --close, keeps the unpushed-commits pre-flight so
                nothing revisitable is lost. Mutually exclusive with --close.
                Requires an existing PR.
```

- [ ] **Step 6: Run the new tests to verify they pass**

Run: `bats test/merge-pr.bats -f punt`
Expected: PASS (all 10 punt tests green).

- [ ] **Step 7: Run the full suite to verify no regressions**

Run: `bats test/merge-pr.bats`
Expected: PASS (every existing test still green — `--punt` adds a branch and changes no existing gating).

- [ ] **Step 8: Lint the script**

Run: `shfmt -d -s -i 4 bin/merge-pr && precious lint --path bin/merge-pr`
Expected: no diff, no lint errors. Fix formatting with `shfmt -w -s -i 4 bin/merge-pr` if needed.

- [ ] **Step 9: Commit**

```bash
git add bin/merge-pr test/merge-pr.bats
git commit -m "$(cat <<'EOF'
merge-pr: add --punt to tear down a worktree, leaving the PR open

--punt removes the worktree, local branch, and tmux session but does not
merge or close the PR and does not delete origin/<branch>, so the work can
be revisited later. Keeps the unpushed-commits guard (unlike --close) and
is mutually exclusive with --close (post-loop check, so both orderings are
refused before the remote-delete block could run).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- Change 1 (parse `--punt`, post-loop mutual exclusion) → Steps 3.
- Change 2 (require a PR) → inherited; no code (the `gh pr view` failure `else` branch already exits 1 when `close_mode` is empty). Covered by the "refuses when no PR exists" test.
- Change 3 (guard on OPEN) → inherited; no code (the `pr_state == OPEN` resolution already fires). Covered by the "refuses on unpushed commits" test.
- Change 4 (skip dispatch, state-aware line) → Step 4.
- Change 5 (usage text) → Step 5.
- Remote-branch preservation → inherited (delete block gated on `close_mode`). Covered by the OPEN/MERGED/CLOSED "leaves the remote branch" assertions.
- Main-working-tree reuse → covered by the main-working-tree test.
- Tests 1-9 from the spec → all present (spec test 3 "both orderings" and the remote-intact assertion are in the mutual-exclusion test).

**Placeholder scan:** none — every step has concrete code/commands.

**Type/name consistency:** flag is `--punt` and variable `punt_mode` throughout; info strings `leaving PR OPEN (--punt)` and `leaving PR ($pr_state) untouched (--punt)` match the test assertions (`leaving PR OPEN (--punt)`, `untouched`); mutual-exclusion message contains `mutually exclusive` matching the test.
