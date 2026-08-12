# merge-pr: refresh the tracking ref before the unpushed-commits pre-flight

Issue: #1007

## Problem

`bin/merge-pr`'s "no unpushed commits" pre-flight trusts the local
remote-tracking ref without checking whether it is current:

```sh
unpushed=$(git rev-list --count '@{u}..HEAD')
```

When `refs/remotes/origin/$branch` is stale, this counts commits that are
already on the remote and blocks the merge with a phantom count:

```
merge-pr: branch '<branch>' has N unpushed commit(s) — push first
```

Pushing again does not help — nothing is unpushed. Local `HEAD` and the branch
on the remote are the same commit; only the tracking ref disagrees. The count
is also inflated beyond the branch's own commits, because a stale ref predates
whatever the base branch gained since.

### How the ref goes stale

Git updates `refs/remotes/<remote>/*` only when the push target is a configured
*remote*. A push to a literal URL — the usual fallback when the configured
remote's transport is unavailable in a given environment — updates the branch
on the server but no tracking ref locally. Any environment that routinely
pushes that way leaves the ref stale after every push, so this is reproducible
rather than occasional.

### Why only this path is affected

The script already reasons about this hazard, but only on the tracking-*repair*
path. When `@{u}` fails to resolve, the repair path asks the remote directly
(`git ls-remote`) and refetches the single ref with an explicit
`+refs/heads/$branch:refs/remotes/origin/$branch` refspec, noting that the local
ref "may be stale relative to what origin holds."

When `@{u}` *does* resolve, none of that runs — the unpushed check goes straight
to `git rev-list '@{u}..HEAD'` against whatever the tracking ref happens to say.
A resolvable-but-stale upstream is exactly the case the repair path was written
to defend against, and it is the case that slips through.

## Change

Single file: `bin/merge-pr`. Refresh the tracking ref before counting, reusing
the refspec the repair path already trusts.

1. Introduce `refreshed_ref=""` alongside `upstream_ok=1` (the pre-flight
   initialization block). It records whether the tracking ref has already been
   brought current this run.
2. In the repair path, on a successful `git fetch`, set `refreshed_ref=1`. That
   path already fetched the same refspec, so the ref is current and the count
   block must not fetch it a second time.
3. In the count block, before `git rev-list`: if `refreshed_ref` is empty,
   refresh the ref. The script runs under `set -eu -o pipefail`, so the fetch
   **must** use the guarded `if ! ...; then` form — a bare `git fetch` would
   abort the script on failure before any warning runs, and a `|| warn` tail
   trips `set -e` unless `warn` returns 0. Mirror the repair path (line 138) by
   redirecting fetch chatter to stderr so it never pollutes stdout:

   ```sh
   if ! git fetch origin "+refs/heads/$branch:refs/remotes/origin/$branch" >&2; then
       echo "merge-pr: warning: could not refresh 'origin/$branch' — unpushed count may be stale" >&2
   fi
   ```

   On failure, the warning is emitted and the script continues against the
   (possibly stale) ref. A fetch failure is **not** fatal: it keeps the script
   usable when the remote is unreachable (offline, slow remote), falling back to
   today's behaviour. On success or skip, compute `@{u}..HEAD` exactly as today.

### Why this shape

- **Reuses one refspec, one behaviour.** The count path becomes as trustworthy
  as the repair path instead of maintaining a second, weaker notion of "pushed".
- **Keeps `rev-list` semantics.** `@{u}..HEAD` counts only commits reachable
  from `HEAD` but not from the upstream — i.e. genuinely local-ahead commits.
  An `ls-remote` SHA compare (`remote_sha != HEAD`) cannot distinguish
  local-ahead (real unpushed) from local-behind or diverged, and would
  false-flag the latter two as "push first". Refreshing the ref and keeping
  `rev-list` avoids that regression.
- **Force-updates a stale ref.** The leading `+` in the refspec updates a
  non-fast-forward stale ref rather than failing, matching the standard
  remote-tracking refspec and the repair path.
- **No double fetch.** The `refreshed_ref` guard means the common no-repair path
  fetches exactly once, and a session that just repaired tracking does not fetch
  the same refspec twice.

### Assumption

The refresh targets `refs/remotes/origin/$branch`, but `git rev-list` reads
whatever `@{u}` resolves to. This fix assumes `@{u}` resolves to
`origin/$branch` — the normal case, and the exact scenario in the issue (the
tracking *config* still points at origin; only the ref content is stale). If a
branch tracked a non-origin remote, the refresh would update a ref `@{u}` does
not read and the phantom count could persist. The whole script already
hardcodes `origin` elsewhere (the repair path, the teardown `ls-remote`), so
this fix stays consistent with that assumption rather than widening it.

## Tests

Added to `test/merge-pr.bats`, following existing patterns (bare-upstream
`setup_upstream`, `stub_command gh 'exit 1'` to prove the pre-flight was passed
by reaching the PR-lookup failure).

- **Stale tracking ref no longer blocks.** Push a second commit (B) so origin
  and `HEAD` agree at B, then make the tracking ref lag with
  `git update-ref refs/remotes/origin/$branch <A>` (an earlier SHA). This
  faithfully reproduces the phantom count — `@{u}..HEAD` sees B as "unpushed"
  though it is on origin. Assert merge-pr does **not** report "unpushed
  commit(s)" and proceeds past the pre-flight (reaching the gh-stub failure, as
  the existing repair test does). The refresh stays offline — origin is a local
  bare repo — so no network dependency is introduced.
- **Genuinely unpushed still blocks.** A real local-ahead commit still yields
  "unpushed commit" after the refresh, guarding against the refresh masking real
  cases. The existing "refuses when branch has unpushed commits" test
  (`test/merge-pr.bats:142`) covers this — its bare upstream lacks the new
  commit, so the refresh cannot pull it forward and the count stays non-zero.
  Verify it still passes; extend only if a gap appears.
- **Fetch-failure fallback is non-fatal.** Simulate an unreachable remote after
  `setup_upstream` with `git remote set-url origin "$BATS_TEST_TMPDIR/nonexistent.git"`
  (leaves `@{u}` resolvable locally, but the fetch fails). Assert the refresh
  warns yet the script continues past the pre-flight rather than aborting under
  `set -e`. This is the test that actually guards the non-fatal requirement.

The `refreshed_ref` guard (no double fetch on the repair path) is a performance
property, not a correctness one, and is hard to assert without wrapping `git`.
It is left **explicitly untested**; the guard is a single flag check verified by
review.

## Out of scope

- The tracking-repair path's own behaviour (unchanged except for setting
  `refreshed_ref`).
- Close mode, which skips the unpushed pre-flight entirely.
- The `ls-remote` SHA-compare alternative from the issue, rejected above for its
  weaker ahead/behind/diverged semantics.
