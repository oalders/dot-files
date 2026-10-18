# merge-pr: wait out the merge queue before tearing down

## Problem

On a repo with a merge queue, `gh pr merge` (e.g. `merge-pr -s`) enqueues the
PR and exits 0 while the PR is still OPEN. `merge-pr` then tears everything
down: worktree, local branch, tmux session. If a check fails in the queue,
GitHub ejects the PR, but by then nothing local is left:

- oalders/clodhopper no longer shows the PR's session, so there is no red
  failed-check indicator. The user only finds out by visiting GitHub.
- Fixing it means re-running `add-worktree` and rebuilding the session.

This is the same hazard that `merge-pr` already refuses `--auto` for. The
difference is that a merge queue is imposed by the repo, so the user cannot
opt out.

## Goal

    $ merge-pr -s            # repo has a merge queue
    merge-pr: PR queued — waiting for the merge queue (position 3)
    merge-pr: queued — position 1, checks running
    ...
    # merged     -> normal teardown, as today
    # ejected    -> nothing torn down; session/worktree stay; exit non-zero

The pane is held while waiting. The user said this is fine because they don't
need that pane.

## Decided

- **Wait, then tear down.** After `gh pr merge`, if the PR is still OPEN and
  in the merge queue, poll until it leaves the queue. Teardown still kills
  tmux last, so waiting inside the session works.
- **On merge**, run the existing teardown unchanged. Today the "in progress"
  label block runs whenever `pr_state == OPEN`, right after `gh pr merge`
  returns, so the wait must sit between `gh pr merge` and that block, and
  `pr_state` must be set to MERGED after the wait. Labels must not be removed
  on ejection.
- **On ejection** (PR OPEN, removed from the queue), tear nothing down. Print
  that the PR was removed from the queue, plus the reason when available, then
  exit non-zero. The surviving session keeps the PR in clodhopper. The user
  fixes the problem, pushes, and re-runs `merge-pr`.
- **Wait through auto-merge too.** On a merge-queue repo whose required
  checks haven't passed, `gh pr merge` enables auto-merge instead of queuing
  (see `gh pr merge --help`): PR OPEN, `isInMergeQueue` false,
  `autoMergeRequest` set. This is the normal state in the recovery flow (push
  a fix, re-run right away). Treat it as the first phase of the wait:
  - head checks fail → tear nothing down, exit non-zero (like an ejection);
  - PR enters the queue → keep waiting as above.

  Invariant: an OPEN PR never falls through to teardown. If after
  `gh pr merge` the PR is OPEN with neither a queue entry nor auto-merge
  (after a short grace period), tear nothing down and exit non-zero.

  Accepted caveats (told to the user):
  - Ctrl-C does not cancel the merge; GitHub still merges later. The Ctrl-C
    hint should mention `gh pr merge --disable-auto`.
  - Commits pushed during the wait are merged too.
  - With no timeout, a missing required approval waits forever.
- **Detect the queue from GitHub**, not from a flag. `gh pr view --json`
  exposes no queue fields, so use `gh api graphql` on `pullRequest {
  state isInMergeQueue mergeQueueEntry { position state } }`.
- **Poll every 60s.** The user isn't in a hurry once the merge is kicked off.
- **Stay in bash.** The wait is a small loop around one `gh` call. A port is a
  separate decision.
- **The `--auto` / `--auto-merge` refusal stays.** It is a separate opt-in that
  this design does not cover.

## Builder's calls (stated to the user; not their requirements)

- Print a status line when position or state changes, not on every poll.
- **No timeout.** Wait until the PR merges or is ejected.
- **Ctrl-C while waiting** stops watching and leaves everything intact. The PR
  stays queued. Print a hint that re-running `merge-pr` resumes. On a re-run:
  - PR MERGED: the existing already-merged teardown path runs.
  - PR still OPEN and queued, or auto-merge already enabled: go straight to
    waiting without calling `gh pr merge` again (check `isInMergeQueue` and
    `autoMergeRequest` first).
- **Repos without a merge queue:** no behavior change. If `gh pr merge`
  merges directly, the PR is MERGED and teardown runs immediately.
- **`--close` and `--punt`:** unaffected. The wait only applies in merge mode.
- **CLOSED during the wait** (someone closed the PR): stop and tear nothing
  down. Report it and exit non-zero.
- **Re-check safety after the wait.** The wait can be long and the user may
  keep working in other panes. Before teardown, re-run the dirty-worktree and
  unpushed-commits checks. If either fails, leave everything in place and exit
  non-zero with the reason.
- **Main-working-tree path waits too.** It runs the same wait before it
  switches branch and deletes the local branch.
- **Exit codes:** one non-zero code (1) for every "not torn down" outcome,
  each with its own message. Nothing reads the code.

## Left to the builder

- **Ejection signal.** Don't infer ejection from `isInMergeQueue == false`
  alone. It lags right after enqueue, and a fast ejection can happen before
  the first poll. Suggested approach: read the PR timeline for a
  `RemovedFromMergeQueueEvent` dated after this run's enqueue, then re-read and
  confirm the PR is still OPEN. That event's `reason` also gives the ejection
  reason cheaply. If GitHub doesn't clear auto-merge on ejection, an OPEN PR
  with auto-merge still set may re-enter the queue. Verify the behavior and
  handle it.
- **Ejection reason.** Queue checks run on a `gh-readonly-queue/...` commit,
  not the PR head, so the PR's `statusCheckRollup` may not show them. Report
  what can be found cheaply. If nothing can be found, a link to the PR is
  enough.
- **Transient `gh` failures** during polling (network, rate limit): retry on
  the next poll and don't treat them as ejection. Give up only after several
  consecutive failures, and leave everything intact when it does.
- **Tests.** Extend `test/merge-pr.bats` with the existing `gh` stub approach
  to cover: queued then merged (teardown runs); queued then ejected (no
  teardown, non-zero exit, labels kept); auto-merge then queued then merged;
  auto-merge then head check fails (no teardown); direct merge (unchanged);
  re-run while queued and while auto-merge is pending (waits, no second
  `gh pr merge`); dirty worktree after the wait (no teardown); transient poll
  failure. Inject the poll
  interval through an env var so tests don't sleep.
- **Usage text.** Update `usage()` to describe the wait.

## Non-goals

- Backgrounding the wait or giving the prompt back.
- Desktop or other out-of-band notifications.
- Porting `merge-pr` off bash.
- Changing clodhopper, or adding a tmux rename as a stopgap signal.

## Known gap, fixed elsewhere

clodhopper reads only `statusCheckRollup` on the PR head (`server.go:577`),
so a **queue** ejection keeps a green badge. Failures during the auto-merge
phase do show, because those checks run on the head. The user will teach
clodhopper about merge-queue ejections in a separate change. Until then, the
held pane and the exit code are the only signal for a queue ejection.
