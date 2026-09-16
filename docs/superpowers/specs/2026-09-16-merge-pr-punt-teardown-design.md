# merge-pr: `--punt` — tear down a worktree without touching the PR

## Problem

`merge-pr` has two terminal modes: default (`gh pr merge` + teardown) and
`--close` (`gh pr close` + teardown + delete the remote branch). Both act on
the PR and both end the branch's life.

There is no way to tear down a worktree — remove it, delete the local branch,
kill the tmux session — while leaving the PR **OPEN** and the remote branch
**intact**, so the work can be revisited later by re-creating a worktree from
`origin/<branch>`. Today the user must either keep the worktree around (which
`kill-worktree-procs` exists to discourage — stale worktrees accumulate agent
processes) or close the PR and lose its review state and discussion.

## Goal

    $ merge-pr --punt        # in worktree, PR left OPEN
    # worktree removed, local branch deleted, tmux session killed;
    # PR still OPEN, origin/<branch> still present.

Later:

    $ add-worktree <branch>  # re-fetches origin/<branch>, resume work

`--punt` "punts" on the merge/close decision and defers it to a later session.

## Design

`--punt` reuses the entire existing teardown path. It differs from the two
existing modes in exactly three ways, and — because of how the current gating
is written — two of the three fall out for free:

| Behavior | default (merge) | `--close` | `--punt` |
|---|---|---|---|
| Acts on the PR | `gh pr merge` | `gh pr close` | **nothing** |
| Deletes remote branch | on merge (GitHub) | yes, explicit | **no** |
| Unpushed-commits guard | enforced | skipped | **enforced** |
| Dirty worktree | refuse unless `--force` | refuse unless `--force` | refuse unless `--force` |
| Remove worktree / delete local branch / kill tmux | yes | yes | yes |

### Why the guard is inherited, and why it matters

The upstream / unpushed-commit pre-flight is gated on `[[ -z "$close_mode" ]]`
(`bin/merge-pr:84`). `--punt` is a separate flag, so that block runs unchanged
and the guard is enforced automatically. This is exactly what we want:
`--punt` discards all local state (worktree + local branch), so anything the
user intends to revisit **must** already be on `origin/<branch>` first.
Refusing on unpushed commits / no upstream is the safety property that makes
"revisit later" real rather than a way to silently lose work.

The `--force` opt-in still covers a *dirty* worktree (uncommitted changes the
user is willing to discard), matching merge mode. It does **not** override the
unpushed-*committed* guard — that is deliberate and identical to merge mode.

### Why remote-branch deletion is skipped for free

The explicit remote-branch delete is gated on `[[ -n "$close_mode" ]]`
(`bin/merge-pr:310`). `--punt` is not close mode, so it is skipped —
`origin/<branch>` survives, which is the whole point.

### Changes in `bin/merge-pr`

1. **Parse `--punt`** in the argument loop. Add `punt_mode=""`; set it on
   `--punt`. Like `--close` and `-f/--force`, it is consumed here and must not
   be forwarded to `gh`.

   **Refuse `--punt` + `--close` with a POST-LOOP check, not an in-loop arm.**
   This is load-bearing. The arg loop sets `close_mode`/`punt_mode` one at a
   time in argument order, so an in-loop check on the `--punt` arm cannot see a
   `--close` that comes later (or vice versa). If both flags survive, the
   consequence is the worst possible: the dispatch skip (change 4) suppresses
   `gh pr close`, but the remote-branch delete (`bin/merge-pr:310`) is gated on
   `close_mode` *alone* and would still delete `origin/<branch>` — destroying
   exactly what `--punt` promises to preserve. So, immediately after the loop
   and before any pre-flight, add:
   `if [[ -n "$punt_mode" && -n "$close_mode" ]]; then <error>; exit 2; fi`,
   with a mutual-exclusion message in the `--auto` refusal style.

2. **Require a PR to exist** — a deliberate scope choice, not a technical
   necessity. `merge-pr` is a PR tool and `--punt` means "leave *the PR* open,"
   so a branch with no PR is out of scope (tear such a branch down manually).
   In the `gh pr view` failure branch (`bin/merge-pr:202`), keep the existing
   merge-mode behavior for `--punt`: if a deferred `preflight_block_reason` is
   set, surface it; otherwise "no PR found" and `exit 1`. (The `no_pr`
   special-casing stays exclusive to `--close`.) Note this requirement is
   *not* justified by needing `pr_base`: the normal linked-worktree teardown
   deletes the branch with `git branch -D` and never reads `pr_base`; only the
   main-working-tree path (`bin/merge-pr:345`) uses it, and change 2 guarantees
   it is available there.

3. **Guard enforcement is inherited, not extended.** The deferred-guard
   resolution at `bin/merge-pr:232` already fires when
   `preflight_block_reason` is set and `pr_state == OPEN`. `--punt`'s premise
   is an OPEN PR (a PR that exists is, by definition, pushed), so this existing
   line already blocks a punt-with-unpushed-commits — the case that matters. We
   deliberately do **not** extend it to fire on `punt_mode` in other states: a
   MERGED PR whose remote branch was auto-deleted leaves `@{u}` unresolved
   ("no upstream"), and forcing punt to block there would refuse a clean
   teardown of already-merged work. So punt on OPEN is guarded; punt on a
   terminal PR degrades to plain teardown (see Behavior notes).

4. **Skip the merge/close dispatch.** `--punt` never invokes `gh`. Guard the
   dispatch block (`bin/merge-pr:264`, `if [[ -z "$no_pr" ]]`) to also skip
   when `punt_mode` is set, printing one **state-aware** informational line so
   we never assert a falsehood: when `pr_state == OPEN`, `merge-pr: leaving PR
   OPEN (--punt) — proceeding to cleanup`; otherwise (MERGED/CLOSED) say the PR
   is left untouched, e.g. `merge-pr: leaving PR ($pr_state) untouched (--punt)
   — proceeding to cleanup`. The PR is never merged or closed in any state. The
   base-branch refusal (`bin/merge-pr:238`) stays in force for `--punt` —
   tearing down the base branch's own worktree is still nonsensical.

5. **Usage text.** Document `--punt` alongside `--close`: leaves the PR OPEN
   and the remote branch in place, runs the same teardown, and keeps the
   unpushed-commits pre-flight (unlike `--close`) so revisitable work is
   guaranteed to be on origin.

Everything downstream — the main-working-tree branch-switch/delete path
(`bin/merge-pr:345`) and the linked-worktree cleanup
(`bin/merge-pr:386`: docker teardown, `kill-worktree-procs`, `git worktree
remove`, `git branch -D`, `tmux kill-session`) — is reused unchanged. In the
main-working-tree case `--punt` still needs `pr_base` to switch off the branch
before deleting it, which the required-PR rule (change 2) guarantees.

The tracking-repair self-heal path (`bin/merge-pr:103-137`) is also reused
unchanged for `--punt`: it may `git fetch` and repair upstream config on a
branch that teardown then deletes, which is harmless (the fetch usefully
confirms the branch is on origin) and identical to merge mode. No special-casing.

## Behavior notes

- `--punt` on a PR that is already MERGED or CLOSED: we do not act on the PR
  (it is already terminal), so `--punt` degrades to plain teardown and the
  informational line still prints. No push required in those states, but the
  guard only *blocks* when there are unpushed commits — an already-merged
  branch with everything pushed tears down cleanly.
- `--punt --force`: discards a dirty worktree during removal, same as merge
  mode; still refuses on unpushed committed work.

## Testing

Add to `test/merge-pr.bats`, reusing the existing helpers
(`setup_feature_worktree` pushes `feature` to origin; `gh`/`tmux` stubs):

1. **`--punt: tears down worktree, keeps PR OPEN and remote branch`** — stub
   `gh` to return `OPEN`; assert status 0, worktree gone, local branch gone,
   `gh pr merge`/`gh pr close` were **not** called (stub records no such
   invocation), `origin/feature` still resolves via `git ls-remote`, and the
   output contains the "leaving PR OPEN" line.
2. **`--punt: refuses on unpushed commits`** — stub `gh` to return `OPEN`, add
   a local commit not on origin; assert non-zero status, "push first" in
   output, and the worktree is **still present** (no teardown).
3. **`--punt: refuses when combined with --close`** — assert exit 2 and a
   mutual-exclusion message, **no `gh` call, and `origin/feature` still
   resolves** (proves the remote branch was not touched — the B1 failure mode).
   Cover both orderings: `--punt --close` and `--close --punt`.
4. **`--punt --force: tears down a dirty worktree`** — dirty the worktree,
   pass `--punt --force`; assert teardown completes and the PR was not acted
   on.
5. **`--punt: refuses when no PR exists`** — stub `gh pr view` to fail; assert
   `exit 1` and "no PR found", worktree **still present**. (The differentiator
   from `--close`, which proceeds on no PR.)
6. **`--punt: on a MERGED PR tears down, leaves remote branch`** — stub `gh` to
   return `MERGED`; assert status 0, worktree gone, no `gh pr merge/close`
   call, `origin/feature` still resolves, and the "untouched" (not "OPEN")
   info line.
7. **`--punt: on a CLOSED PR tears down`** — stub `gh` to return `CLOSED`;
   assert status 0, teardown done, no `gh` action, remote branch intact.
8. **`--punt: refuses on the base branch`** — run with `branch == baseRefName`;
   assert the existing base-branch refusal fires (no teardown).
9. **`--punt: from the main working tree`** — run from the main checkout (not a
   linked worktree); assert it switches to `pr_base`, deletes the local branch,
   and leaves `origin/feature` + the PR in place.

All existing tests must pass untouched — `--punt` adds a branch of behavior
and changes none of the existing gating.
