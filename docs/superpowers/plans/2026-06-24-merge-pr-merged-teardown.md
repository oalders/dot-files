# merge-pr MERGED Teardown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let plain `merge-pr` tear down a worktree whose PR is already MERGED without forcing a push of the (often already-deleted) branch.

**Architecture:** Deferred bail. The upstream/unpushed-commit pre-flight in `bin/merge-pr` records its failure reason into a variable instead of exiting. After the PR-state lookup, the script resolves that reason: emit it on lookup failure or for an OPEN PR, but ignore it for a MERGED PR (which is torn down without `gh pr merge`).

**Tech Stack:** Bash (`set -eu -o pipefail`), `gh` CLI, `git worktree`, `tmux`; tests in Bats (`test/merge-pr.bats`, helpers in `test/helpers.bash`).

## Global Constraints

- Script header is `set -eu -o pipefail` — every variable referenced must be defined; an unresolved `@{u}` in a command substitution aborts the script.
- Shell indentation is 4 spaces (`shfmt -i 4 -s`), enforced via `precious`.
- Em dash (`—`) is used verbatim in existing user-facing messages; preserve it.
- The interactive tracking-repair path (branch on origin, tracking misconfigured) must keep exiting immediately — it is not a missing push and must not be deferred.
- Close mode (`--close`) skips this pre-flight entirely; the new variable must stay safe (defined) on that path.

**Spec:** `docs/superpowers/specs/2026-06-24-merge-pr-merged-teardown-design.md`

---

### Task 1: Auto-skip the push pre-flight for a MERGED PR

**Files:**
- Modify: `bin/merge-pr` (pre-flight block ~lines 82–126; PR lookup ~lines 153–158; usage text ~lines 6–11)
- Test: `test/merge-pr.bats` (new test near the existing `cleanup:` tests ~line 206)

**Interfaces:**
- Consumes: existing helpers in `test/helpers.bash` — `_ready_repo` (= `setup_git_repo` + `setup_upstream`), `setup_feature_worktree` (creates `WORKTREE_DIR` on branch `feature`, pushed to origin; sets `REPO_DIR`), `stub_command`.
- Produces: no new public interface. Internal-to-script variables `preflight_block_reason` (string, "" when no deferred failure) and `upstream_ok` (1/0).

- [ ] **Step 1: Write the failing test**

Add this test to `test/merge-pr.bats`, immediately after the `@test "cleanup: removes a clean worktree without submodules"` block (after line 206):

```bash
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
```

- [ ] **Step 2: Run the new test to verify it fails**

Run: `bats test/merge-pr.bats -f "MERGED PR with no upstream"`
Expected: FAIL. With the current script the no-upstream pre-flight bails before the PR lookup, so `$status` is 1 and `$output` contains "has no upstream — push first" — the `status -eq 0` / `!= *"push first"*` assertions fail.

- [ ] **Step 3: Defer the push pre-flight instead of exiting**

In `bin/merge-pr`, replace the entire pre-flight block. The current block begins at the `if [[ -z "$close_mode" ]]` line (~82) and ends at its closing `fi` (~126). Replace **from that `if` line through that `fi`** with:

```bash
# Deferred push pre-flight failure (no upstream / unpushed commits). The push
# pre-flight exists only to satisfy `gh pr merge`, which runs only for an OPEN
# PR; an already-MERGED PR is torn down without pushing, so the failure is moot
# there. Record the reason and resolve it once the PR state is known (below).
# Initialized unconditionally so it stays defined under `set -u`, including in
# close mode where the pre-flight block is skipped.
preflight_block_reason=""

if [[ -z "$close_mode" ]]; then
    # upstream_ok defaults to 1: on a normally tracked branch the `@{u}` block
    # below is skipped entirely, yet the unpushed-commit check still has to run.
    # Only the genuinely-no-upstream path clears it — there `@{u}` is unresolved
    # and `git rev-list '@{u}..HEAD'` would abort the script under `set -e`.
    upstream_ok=1

    # Pre-flight: branch must have an upstream.
    #
    # `@{u}` fails both when the branch is genuinely unpushed AND when it is
    # already on origin but its local tracking config is wrong (e.g.
    # branch.<name>.remote points at a clone URL instead of "origin"). In the
    # latter case "push first" misdiagnoses the problem — the branch is pushed;
    # only the tracking config needs repair. Distinguish the two by asking
    # origin directly.
    if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        # Query the full ref path, not a bare name: `ls-remote origin foo`
        # tail-matches path components and would also match `refs/heads/x/foo`,
        # false-flagging a genuinely unpushed branch. The output is a single
        # line, so `grep -q` consuming it before ls-remote blocks keeps the
        # pipe safe under pipefail — don't widen this query.
        if git ls-remote origin "refs/heads/$branch" 2>/dev/null | grep -q .; then
            # Branch IS on origin; only tracking config is wrong. This is not a
            # missing push, and cannot arise for a MERGED PR (its remote branch
            # is gone), so handle it immediately rather than deferring.
            echo "merge-pr: branch '$branch' is on origin, but local tracking config" >&2
            echo "          is wrong, so '@{u}' does not resolve. The branch is" >&2
            echo "          already pushed — this is a config issue, not a missing push." >&2
            printf "merge-pr: repair with 'git branch --set-upstream-to=origin/%s' and continue? [y/N] " "$branch" >&2
            # Default to bailing: empty input (just Enter), EOF, or a
            # non-interactive stdin all leave tracking untouched.
            read -r reply || reply=""
            case "$reply" in
                [Yy]*)
                    git branch --set-upstream-to="origin/$branch" >&2
                    ;;
                *)
                    echo "merge-pr: aborted — fix tracking config and re-run." >&2
                    exit 1
                    ;;
            esac
        else
            # Genuinely unpushed. Defer instead of bailing — a MERGED PR needs
            # no push. `@{u}` is unresolved, so skip the unpushed-commit check.
            preflight_block_reason="branch '$branch' has no upstream — push first"
            upstream_ok=0
        fi
    fi

    # Pre-flight: no unpushed commits. Runs only when `@{u}` resolves; a
    # successful tracking-repair above leaves upstream_ok=1, so it still runs
    # after a repair.
    if [[ "$upstream_ok" -eq 1 ]]; then
        unpushed=$(git rev-list --count '@{u}..HEAD')
        if [[ "$unpushed" -ne 0 ]]; then
            preflight_block_reason="branch '$branch' has $unpushed unpushed commit(s) — push first"
        fi
    fi
fi
```

- [ ] **Step 4: Resolve the deferred reason at the PR lookup**

In `bin/merge-pr`, find the PR lookup block (~lines 153–158):

```bash
# PR lookup: state + baseRefName in a single call.
if ! pr_info=$(gh pr view --json state,baseRefName -q '[.state, .baseRefName] | @tsv' 2>/dev/null); then
    echo "merge-pr: no PR found for branch '$branch'" >&2
    exit 1
fi
pr_state=$(echo "$pr_info" | cut -f1)
pr_base=$(echo "$pr_info" | cut -f2)
```

Replace it with:

```bash
# PR lookup: state + baseRefName in a single call.
if ! pr_info=$(gh pr view --json state,baseRefName -q '[.state, .baseRefName] | @tsv' 2>/dev/null); then
    # A deferred push pre-flight failure means we can't even identify the PR;
    # surface that actionable reason instead of the generic "no PR found".
    if [[ -n "$preflight_block_reason" ]]; then
        echo "merge-pr: $preflight_block_reason" >&2
        exit 1
    fi
    echo "merge-pr: no PR found for branch '$branch'" >&2
    exit 1
fi
pr_state=$(echo "$pr_info" | cut -f1)
pr_base=$(echo "$pr_info" | cut -f2)

# Resolve a deferred push pre-flight failure. It matters only when we'll run
# `gh pr merge` (an OPEN PR). A MERGED PR is torn down without pushing — the
# whole point of deferring. CLOSED/other states fall through to the dispatch
# refusal below.
if [[ -n "$preflight_block_reason" && "$pr_state" == "OPEN" ]]; then
    echo "merge-pr: $preflight_block_reason" >&2
    exit 1
fi
```

- [ ] **Step 5: Update the usage text**

In `bin/merge-pr`, in the `usage()` heredoc, find this paragraph (~lines 9–11):

```
Merges the current branch's PR via `gh pr merge`, then removes the
worktree, deletes the local branch, and kills the tmux session for the
worktree. Run from inside the worktree's tmux session.
```

Replace it with:

```
Merges the current branch's PR via `gh pr merge`, then removes the
worktree, deletes the local branch, and kills the tmux session for the
worktree. Run from inside the worktree's tmux session.

If the PR is already MERGED, the merge is skipped and teardown runs even
when the branch is no longer on origin — no push required.
```

- [ ] **Step 6: Run the new test to verify it passes**

Run: `bats test/merge-pr.bats -f "MERGED PR with no upstream"`
Expected: PASS (1 test, 0 failures).

- [ ] **Step 7: Run the full suite to verify zero regression**

Run: `bats test/merge-pr.bats`
Expected: all tests PASS, including the previously-tested `has no upstream`, `unpushed commits`, suffix-match, tracking-repair, `no PR found`, CLOSED/DRAFT, and MERGED-cleanup cases.

- [ ] **Step 8: Lint the script**

Run: `precious lint bin/merge-pr`
Expected: no errors. If `precious` reports formatting, run `precious tidy bin/merge-pr` and re-run the lint and the full test suite (Step 7).

- [ ] **Step 9: Commit**

```bash
git add bin/merge-pr test/merge-pr.bats
git commit -m "merge-pr: tear down an already-MERGED PR without pushing the branch

The upstream/unpushed pre-flight existed only to satisfy gh pr merge, which
runs only for an OPEN PR. Defer its failure instead of exiting, then resolve
it once the PR state is known: a MERGED PR is torn down without a push (the
remote branch is typically gone via delete_branch_on_merge), while OPEN and
lookup-failure cases still report the original message.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Defer, don't exit, in the merge-mode pre-flight (spec §Approach item 1) → Step 3, including `preflight_block_reason=""` and `upstream_ok=1` initialization.
- Resolve on PR-lookup failure (spec item 2) → Step 4, first hunk.
- Resolve on OPEN (spec item 3) → Step 4, second hunk.
- Usage text (spec item 4) → Step 5.
- Keep interactive tracking-repair immediate (spec, Global Constraints) → Step 3 preserves the `[Yy]`/abort `exit 1` path unchanged.
- New test for MERGED + no upstream (spec §Testing) → Steps 1–2, 6.
- Zero-regression claim → Step 7 runs the full suite.

**Placeholder scan:** None — all steps contain literal code and exact commands.

**Type consistency:** `preflight_block_reason` and `upstream_ok` are spelled identically across Steps 3 and 4. The MERGED skip relies on `pr_state` (set in Step 4) — defined before its use in the OPEN-resolution guard.
