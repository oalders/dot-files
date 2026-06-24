# merge-pr: tear down an already-MERGED PR without pushing the branch

## Problem

Running plain `merge-pr` from a worktree to tear it down after the PR has
already been MERGED (e.g. merged via the GitHub UI) can bail with:

    merge-pr: branch 'feature/x' has no upstream — push first

This happens because the upstream/unpushed pre-flight (`bin/merge-pr` lines
82–126) runs *before* the PR-state lookup (line 153). When GitHub's
`delete_branch_on_merge` has removed the remote branch, `@{u}` no longer
resolves, so the pre-flight reports "has no upstream — push first" — forcing
the user to push a *merged* branch back to origin just to satisfy a check
that exists only for `gh pr merge`.

`merge-pr --close` is the only existing way to skip that pre-flight, but it
refuses a MERGED PR (`merge-pr: refusing to close a MERGED PR`, line 199).
There is no path to tear down a merged-and-unpushed branch.

## Goal

Plain `merge-pr` (no new flag) detects that the PR is already MERGED and tears
down the worktree/branch/tmux session without requiring the branch to be on
origin — the same way `--close` already skips the pre-flight, because in both
cases `gh pr merge` is never invoked.

    $ merge-pr        # in worktree, PR already merged, remote branch gone
    merge-pr: PR already MERGED — proceeding to cleanup
    # (no "push first" bail; teardown runs)

## Why the pre-flight is moot for a MERGED PR

The upstream and unpushed-commit pre-flight exists solely to satisfy
`gh pr merge`, which requires the branch to be pushed. `gh pr merge` only runs
for an **OPEN** PR (the `OPEN` arm of the dispatch at line 187). For a MERGED
PR the script skips straight to cleanup, so the branch need not be on origin
at all — identical to the reasoning already documented for `--close` at lines
77–81.

## Approach: deferred bail (preserve ordering)

Several existing tests (`pre-flight: refuses when branch has no upstream`,
`...unpushed commits...`, the suffix-tail-match test) run with **no `gh`
stub** and rely on the pre-flight bailing *before* the PR lookup. Reordering
the lookup above the pre-flight would change what those tests assert and would
change the user-visible message for the "no PR + no upstream" combination.

To avoid that, the pre-flight stays where it is but **records** its failure
reason instead of exiting, and the script **resolves** that reason once the PR
state is known.

### Changes in `bin/merge-pr`

1. **Defer, don't exit, in the merge-mode pre-flight.**
   - Initialize `preflight_block_reason=""` and `upstream_ok=1` before the
     pre-flight. The `upstream_ok=1` default is load-bearing: on a normally
     tracked branch the whole `if ! @{u}` block is skipped, so `upstream_ok`
     is never assigned there, and the unpushed-commit check below must still
     run. Initializing to 0 (or leaving it unset, fatal under `set -u`) would
     silently disable unpushed-commit detection on a normal branch.
   - Replace the two terminal `exit 1` bails with assignments to
     `preflight_block_reason`:
     - genuinely no upstream → `branch '$branch' has no upstream — push first`
     - unpushed commits → `branch '$branch' has $unpushed unpushed commit(s) — push first`
   - Keep the **interactive tracking-repair path** (the "branch is on origin
     but local tracking config is wrong" case) exiting immediately as today.
     It is a config issue, not a missing push, and cannot arise for a MERGED
     PR (the remote branch is gone), so it stays unchanged.
   - Guard the unpushed-commits check (`git rev-list --count '@{u}..HEAD'`)
     behind an `upstream_ok` flag. With the no-upstream `exit 1` removed,
     control can now fall through to this `git rev-list` with `@{u}`
     unresolved, which would abort under `set -e`. Set `upstream_ok=0` when
     recording the no-upstream reason and only run the unpushed check when
     `upstream_ok` is 1. A successful tracking-repair leaves `upstream_ok=1`,
     so the unpushed check still runs after a repair (preserves the
     "accepting the tracking-repair prompt" contract).

2. **Resolve on PR-lookup failure.** In the `gh pr view` failure branch
   (line 153): if `preflight_block_reason` is set, emit it and `exit 1`;
   otherwise emit the existing "no PR found" and `exit 1`. This preserves
   "has no upstream" / "push first" / "unpushed commit" for the no-`gh`-stub
   tests, and "no PR found" for the test whose repo *has* an upstream.

3. **Resolve on OPEN.** After `pr_state` is parsed (line ~158) and before the
   base-branch check: if `preflight_block_reason` is set **and**
   `pr_state == OPEN`, emit it and `exit 1` — an OPEN PR genuinely needs the
   branch pushed for `gh pr merge`. For **MERGED**, the reason is ignored and
   teardown proceeds (the whole point of the fix). CLOSED/DRAFT/other states
   fall through to the existing dispatch refusal.

4. **Usage text.** Add a line noting that an already-MERGED PR is cleaned up
   even when its branch is no longer on origin (no push required).

`preflight_block_reason` is initialized to `""` unconditionally, before the
merge-mode block (`[[ -z "$close_mode" ]]`). It is therefore always defined —
including in close mode, where the pre-flight block is skipped — so every read
of it is safe under `set -u` without needing `${preflight_block_reason:-}`.

## Behavior deltas

All three are minor and are improvements; none is covered by an existing test:

- `{no PR} + {no upstream}` → still reports "has no upstream" (the deferred
  reason wins on lookup failure). **No change.**
- `{no upstream} + {dirty worktree, no --force}` → message becomes
  "uncommitted changes — commit/stash or --force" instead of "push first",
  because the dirty-worktree check (line 136) now runs before the deferred
  reason is resolved. More actionable.
- `{CLOSED} + {no upstream}` in merge mode → now "refusing to act on PR in
  state 'CLOSED'" instead of "push first". More accurate.

A MERGED PR with a **dirty** worktree and no `--force` still bails on the
dirty-worktree check (line 136), as it should — teardown must not silently
discard uncommitted work. `--force` remains the opt-in.

## Testing

All existing `test/merge-pr.bats` tests pass untouched. Verified setups:
`_ready_repo` = `setup_git_repo` + `setup_upstream` (branch pushed, tracking
set, no unpushed commits), and `setup_feature_worktree` pushes `feature` to
origin — so none of them exercise the merged-and-unpushed path that changes.

Add one new test for the fix:

- **`cleanup: MERGED PR with no upstream tears down without 'push first'`** —
  set up a feature worktree whose branch has no resolvable upstream
  (simulating the auto-deleted remote: e.g. remove the remote `feature` ref /
  tracking so `@{u}` fails), stub `gh` to return `MERGED`, stub `tmux` inert.
  Assert: status 0, the worktree directory is gone, the local branch is gone,
  and the output contains neither "push first" nor "has no upstream".
