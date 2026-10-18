# merge-pr Merge-Queue Wait Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `merge-pr` waits for a queued or auto-merge PR to actually merge
before tearing down. If the PR is ejected or its checks fail, it tears nothing
down.

**Architecture:** `pr_queue_status` makes one `gh api graphql` call and prints
a `|`-joined status line. `classify_status` turns that line into a single word.
`wait_for_merge` polls and classifies until the PR merges, and exits 1 on any
other outcome. All of this goes in `bin/merge-pr`'s OPEN-merge dispatch arm,
between `gh pr merge` and the label block. The main-tree path and teardown
inherit the wait without further changes.

**Tech Stack:** bash, `gh` 2.102 (`gh api graphql`), bats.

**Spec:** `docs/superpowers/specs/2026-10-17-merge-pr-merge-queue-design.md`

## Global Constraints

- Poll interval is 60s, overridable through `MERGE_PR_POLL_INTERVAL`. Tests
  set it to `0`.
- No timeout.
- `set -eu -o pipefail` stays. Every `gh` call in the wait path must be
  guarded (`if ! x=$(...)`), so one failure never aborts the script.
- An OPEN PR never reaches teardown. Every non-merged outcome exits `1` and
  leaves the worktree, branch, and tmux session in place.
- `--close` and `--punt` are untouched. The `--auto` refusal stays.
- Messages use the existing `merge-pr: ` prefix. Errors go to stderr, status
  lines to stdout.

## Review Focus

1. **A removal event left over from an earlier attempt** must not count as an
   ejection. Covered by a Task 1 test: "stale removal event is not an
   ejection".
2. **`isInMergeQueue` reads false right after enqueue.** This must not count as
   an ejection or a failure for at most 2 polls. Covered by a Task 2 test:
   "brief unsettled read then queued".
3. **Re-running while the PR is already queued** must not call `gh pr merge` a
   second time. Covered by a Task 2 test.
4. **Commits made in another pane during the wait** must not be destroyed by
   `git branch -D`. Covered by a Task 3 test: "new commit during wait".
5. **Existing direct-merge repos** must behave exactly as before. Covered by
   the existing OPEN-merge tests, which now see `MERGED` on the first probe.

---

### Task 1: Status probe, classifier, and queue wait loop

**Files:**
- Modify: `bin/merge-pr`. Change the PR lookup at line ~225 to also fetch
  `.number`. Add the functions near the top, after `usage()`. Replace the
  `gh pr merge "${gh_args[@]}"` line in the OPEN arm (~line 307).
- Test: `test/merge-pr.bats`

**Interfaces:**
- Produces (bats): `_queue_stub <probe-line>...` (gh stub only) and `_queue_setup <probe-line>...` (linked-worktree fixture + stub).
- Produces (script):
  - `pr_number`: a global set from the lookup's 3rd TSV field. It may be
    empty under old stubs.
  - `pr_queue_status`: prints one line,
    `state|in_queue|position|auto_merge|head_checks|removed_id|removed_reason|url`.
    `in_queue` and `auto_merge` are `true`/`false`. Empty fields stay empty.
    It returns non-zero on `gh` failure.
  - `classify_status <line> <baseline_removed_id>`: prints exactly one of
    `merged closed ejected queued automerge checks_failed unsettled invalid`.
  - `wait_for_merge <baseline_removed_id>`: returns 0 only once the PR is
    MERGED. Every other outcome makes it exit 1.

- [ ] **Step 1: Make the test harness answer probes**

  1. In `setup()`, add `export MERGE_PR_POLL_INTERVAL=0`.
  2. Add a `graphql)` arm (`"api graphql")` in `_label_gh_stub`) that prints
     `MERGED|false||false|SUCCESS|||u` to every existing gh stub that merges
     an OPEN PR. These are the stubs at lines ~371, ~793, ~858, ~887 and
     `_label_gh_stub`.
  3. Add this helper. The stub pops one line per `gh api graphql` call from
     `$BATS_TEST_TMPDIR/probes` and repeats the last line when the file runs
     out. It touches `merge-was-called` on `pr merge` and appends the call to
     `merge.log`. A non-empty `$BATS_TEST_TMPDIR/on-probe-<n>` file is sourced
     on the n-th probe, so tests can inject side effects. A probe line of
     `FAIL` makes that probe exit 1.

```bash
# Usage: _queue_stub <probe-line>...   (one line per successive probe)
_queue_stub() {
    printf '%s\n' "$@" >"$BATS_TEST_TMPDIR/probes"
    stub_command gh '
echo "$*" >>"$BATS_TEST_TMPDIR/gh.log"
case "$1 $2" in
    "pr view") printf "OPEN\tmain\t7\n" ;;
    "pr merge") : >"$BATS_TEST_TMPDIR/merge-was-called"; echo merge >>"$BATS_TEST_TMPDIR/merge.log" ;;
    "api graphql")
        n=$(( $(cat "$BATS_TEST_TMPDIR/probe-count" 2>/dev/null || echo 0) + 1 ))
        echo "$n" >"$BATS_TEST_TMPDIR/probe-count"
        [[ -s "$BATS_TEST_TMPDIR/on-probe-$n" ]] && . "$BATS_TEST_TMPDIR/on-probe-$n"
        line=$(sed -n "${n}p" "$BATS_TEST_TMPDIR/probes")
        [[ -z $line ]] && line=$(tail -n 1 "$BATS_TEST_TMPDIR/probes")
        [[ $line == FAIL ]] && exit 1
        echo "$line"
        ;;
esac
exit 0
'
}

# Linked-worktree fixture plus the queue stub.
_queue_setup() {
    _ready_repo
    setup_feature_worktree
    unset TMUX
    stub_command tmux 'exit 0'
    _queue_stub "$@"
}
```

- [ ] **Step 2: Write the failing tests.** In each probe list, the 1st line is
  the pre-merge probe.

```bash
@test "queue: queued then merged tears down" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|2|false|SUCCESS|||u' \
        'OPEN|true|1|false|SUCCESS|||u' 'MERGED|false||false|SUCCESS|||u'
    run "$MERGE_PR" -s
    [ "$status" -eq 0 ]
    [[ "$output" == *"PR queued — waiting for the merge queue (position 2)"* ]]
    [[ "$output" == *"still queued — position 1"* ]]
    [[ "$output" == *"PR merged — proceeding to cleanup"* ]]
    [ ! -d "$WORKTREE_DIR" ]
}

@test "queue: ejected PR tears nothing down and keeps labels" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|1|false|SUCCESS|||u' \
        'OPEN|false||false|FAILURE|RFMQ_1|FAILED_CHECKS|https://x/pull/7'
    run "$MERGE_PR" -s
    [ "$status" -eq 1 ]
    [[ "$output" == *"PR was removed from the merge queue (FAILED_CHECKS) — nothing torn down"* ]]
    [[ "$output" == *"https://x/pull/7"* ]]
    [ -d "$WORKTREE_DIR" ]
    run git -C "$REPO_DIR" branch --list feature
    [ -n "$output" ]
    run grep -c "issue" "$BATS_TEST_TMPDIR/gh.log"   # no label lookups happened
    [ "$status" -ne 0 ]
}

@test "queue: stale removal event is not an ejection" {
    _queue_setup 'OPEN|false||false|SUCCESS|RFMQ_old|FAILED_CHECKS|u' \
        'OPEN|true|1|false|SUCCESS|RFMQ_old|FAILED_CHECKS|u' \
        'MERGED|false||false|SUCCESS|RFMQ_old|FAILED_CHECKS|u'
    run "$MERGE_PR" -s
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
}

@test "queue: PR closed during the wait tears nothing down" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|1|false|SUCCESS|||u' \
        'CLOSED|false||false|SUCCESS|||u'
    run "$MERGE_PR" -s
    [ "$status" -eq 1 ]
    [[ "$output" == *"PR was closed while waiting — nothing torn down"* ]]
    [ -d "$WORKTREE_DIR" ]
}

@test "queue: main working tree waits before deleting the branch" {
    _ready_repo
    cd "$REPO_DIR"
    git checkout -q -b feature
    git push -q -u origin feature
    unset TMUX
    stub_command tmux 'exit 0'
    _queue_stub 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|1|false|SUCCESS|||u' \
        'OPEN|false||false|FAILURE|RFMQ_1|FAILED_CHECKS|u'
    run "$MERGE_PR" -s
    [ "$status" -eq 1 ]
    [ "$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)" == feature ]
}

@test "queue: transient probe failures are retried" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|1|false|SUCCESS|||u' \
        FAIL FAIL 'MERGED|false||false|SUCCESS|||u'
    run "$MERGE_PR" -s
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
}

@test "queue: five consecutive probe failures give up without teardown" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|1|false|SUCCESS|||u' FAIL
    run "$MERGE_PR" -s
    [ "$status" -eq 1 ]
    [[ "$output" == *"could not read PR status from GitHub 5 times in a row — nothing torn down"* ]]
    [ -d "$WORKTREE_DIR" ]
}
```

- [ ] **Step 3: Run the tests and check they fail**

  Run: `bats test/merge-pr.bats -f 'queue:'`
  Expected: all 7 fail. Teardown currently runs right after `gh pr merge`.

- [ ] **Step 4: Implement**

  - **PR lookup:** `-q '[.state, .baseRefName, .number] | @tsv'` with
    `--json state,baseRefName,number`. Set `pr_number=$(echo "$pr_info" | cut -f3)`.
  - **`pr_queue_status`:** run `gh api graphql -F owner='{owner}' -F
    name='{repo}' -F number="$pr_number"`. Use the query and `--jq` below,
    which were verified against PR #1069. Join with `|`, not `@tsv`: `IFS=$'\t'
    read` collapses empty fields.

```text
query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){pullRequest(number:$number){state isInMergeQueue mergeQueueEntry{position} autoMergeRequest{enabledAt} url commits(last:1){nodes{commit{statusCheckRollup{state}}}} timelineItems(last:1,itemTypes:[REMOVED_FROM_MERGE_QUEUE_EVENT]){nodes{... on RemovedFromMergeQueueEvent{id reason}}}}}}

.data.repository.pullRequest | [.state, (.isInMergeQueue|tostring), ((.mergeQueueEntry.position // "")|tostring), ((.autoMergeRequest != null)|tostring), (.commits.nodes[0].commit.statusCheckRollup.state // ""), (.timelineItems.nodes[0].id // ""), (.timelineItems.nodes[0].reason // ""), .url] | join("|")
```

  - **`classify_status`:** check these rules in order and print the first that
    matches.
    1. State is not OPEN/MERGED/CLOSED → `invalid`.
    2. `MERGED` → `merged`.
    3. `CLOSED` → `closed`.
    4. `in_queue=true` → `queued`.
    5. `removed_id` is non-empty and differs from the baseline → `ejected`.
    6. `auto_merge=true` and `head_checks` is `FAILURE` or `ERROR` →
       `checks_failed`.
    7. `auto_merge=true` → `automerge`.
    8. Otherwise → `unsettled`.
  - **`wait_for_merge`:** loop `probe → classify`, and sleep
    `${MERGE_PR_POLL_INTERVAL:-60}` between probes, never before the first
    one. In this task, `automerge`, `checks_failed` and `unsettled` just keep
    waiting; Task 2 gives them their real behavior. A new removal event counts
    as an ejection even if `autoMergeRequest` is still set (rule 5 comes before
    rule 7). This is a plan decision: the user wants to hear about any
    ejection. A probe failure or `invalid` adds to a failure counter, which resets
    on any good read. At 5 failures, print the give-up message and
    `exit 1`. Print a status line only when the classification or the position
    changes.

  Exact copy:

  | Outcome | Message | Stream | Exit |
  |---|---|---|---|
  | first `queued` | `merge-pr: PR queued — waiting for the merge queue (position N)` | stdout | |
  | later `queued`, new position | `merge-pr: still queued — position N` | stdout | |
  | `merged` | `merge-pr: PR merged — proceeding to cleanup` | stdout | returns 0 |
  | `ejected` | `merge-pr: PR was removed from the merge queue (REASON) — nothing torn down`, then `          fix, push, and re-run merge-pr: URL` | stderr | 1 |
  | `closed` | `merge-pr: PR was closed while waiting — nothing torn down` | stderr | 1 |
  | 5 failures | `merge-pr: could not read PR status from GitHub 5 times in a row — nothing torn down; re-run merge-pr to resume waiting` | stderr | 1 |

  - **OPEN merge arm:**
    1. Run `pre=$(pr_queue_status) || pre=""` and take `baseline` from field 6
       of `pre`.
    2. Run `gh pr merge "${gh_args[@]}"`.
    3. Run `wait_for_merge "$baseline"`.
    4. Set `pr_state=MERGED`.

    Step 4 keeps the label block's existing condition correct.

- [ ] **Step 5: Run the whole file and check it passes**

  Run: `bats test/merge-pr.bats`
  Expected: all tests pass, including every pre-existing test.

- [ ] **Step 6: Lint and commit**

```bash
precious lint bin/merge-pr test/merge-pr.bats
git add bin/merge-pr test/merge-pr.bats
git commit -m "Wait for the merge queue in merge-pr before tearing down"
```

---

### Task 2: Auto-merge phase, grace period, and resuming a re-run

**Files:**
- Modify: `bin/merge-pr` (`wait_for_merge` and the OPEN merge arm)
- Test: `test/merge-pr.bats`

**Interfaces:**
- Consumes: `pr_queue_status`, `classify_status`, `wait_for_merge`, and
  `_queue_setup` from Task 1.

- [ ] **Step 1: Write the failing tests**

```bash
@test "automerge: auto-merge then queued then merged tears down" {
    _queue_setup 'OPEN|false||false|PENDING|||u' 'OPEN|false||true|PENDING|||u' \
        'OPEN|true|1|false|SUCCESS|||u' 'MERGED|false||false|SUCCESS|||u'
    run "$MERGE_PR" -s
    [ "$status" -eq 0 ]
    [[ "$output" == *"auto-merge enabled — waiting for required checks"* ]]
    [ ! -d "$WORKTREE_DIR" ]
}

@test "automerge: failing head checks tear nothing down" {
    _queue_setup 'OPEN|false||false|PENDING|||u' 'OPEN|false||true|FAILURE|||https://x/pull/7'
    run "$MERGE_PR" -s
    [ "$status" -eq 1 ]
    [[ "$output" == *"required checks failed while waiting for auto-merge — nothing torn down"* ]]
    [ -d "$WORKTREE_DIR" ]
}

@test "queue: brief unsettled read then queued keeps waiting" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|false||false|SUCCESS|||u' \
        'OPEN|true|1|false|SUCCESS|||u' 'MERGED|false||false|SUCCESS|||u'
    run "$MERGE_PR" -s
    [ "$status" -eq 0 ]
}

@test "queue: neither queued nor auto-merge after grace tears nothing down" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u'
    run "$MERGE_PR" -s
    [ "$status" -eq 1 ]
    [[ "$output" == *"PR is OPEN but neither queued nor set to auto-merge — nothing torn down"* ]]
    [ -d "$WORKTREE_DIR" ]
}

@test "resume: re-run while queued waits without calling gh pr merge" {
    _queue_setup 'OPEN|true|3|false|SUCCESS|||u' 'MERGED|false||false|SUCCESS|||u'
    run "$MERGE_PR" -s
    [ "$status" -eq 0 ]
    [[ "$output" == *"already in the merge queue — waiting"* ]]
    [ ! -e "$BATS_TEST_TMPDIR/merge-was-called" ]
}

@test "resume: re-run while auto-merge is pending waits without calling gh pr merge" {
    _queue_setup 'OPEN|false||true|PENDING|||u' 'MERGED|false||false|SUCCESS|||u'
    run "$MERGE_PR" -s
    [ "$status" -eq 0 ]
    [[ "$output" == *"auto-merge already enabled — waiting"* ]]
    [ ! -e "$BATS_TEST_TMPDIR/merge-was-called" ]
}
```

- [ ] **Step 2: Run the tests and check they fail**

  Run: `bats test/merge-pr.bats -f 'automerge:|resume:|unsettled|grace'`
  Expected: all 6 fail.

- [ ] **Step 3: Implement**

  In `wait_for_merge`:
  - `automerge` keeps waiting. Its first status line is `merge-pr: auto-merge
    enabled — waiting for required checks`.
  - `checks_failed` prints to stderr and exits 1: `merge-pr: required checks
    failed while waiting for auto-merge — nothing torn down`, then `          fix,
    push, and re-run merge-pr: URL`.
  - `unsettled` keeps waiting while it is consecutive and fewer than 3 reads.
    On the 3rd consecutive read, print `merge-pr: PR is OPEN but neither queued
    nor set to auto-merge — nothing torn down` to stderr and exit 1. Any other
    classification resets the count.

  In the OPEN merge arm, classify `pre` against itself (baseline = its own
  `removed_id`) before `gh pr merge`:
  - `queued`: print `merge-pr: PR already in the merge queue — waiting` and
    skip `gh pr merge`.
  - `automerge`: print `merge-pr: auto-merge already enabled — waiting` and
    skip `gh pr merge`.
  - Anything else, including an empty `pre`: call `gh pr merge` as before.

- [ ] **Step 4: Run the whole file and check it passes**

  Run: `bats test/merge-pr.bats`
  Expected: all pass.

- [ ] **Step 5: Lint and commit**

```bash
precious lint bin/merge-pr test/merge-pr.bats
git add bin/merge-pr test/merge-pr.bats
git commit -m "Wait through auto-merge and resume a queued PR in merge-pr"
```

---

### Task 3: Post-wait safety checks, Ctrl-C hint, and usage

**Files:**
- Modify: `bin/merge-pr` (`usage()`, the OPEN merge arm after
  `wait_for_merge`, and an INT trap inside `wait_for_merge`)
- Test: `test/merge-pr.bats`

**Interfaces:**
- Consumes: `wait_for_merge` and `_queue_setup`. Tests use the
  `on-probe-<n>` hook to change the worktree mid-wait.

- [ ] **Step 1: Write the failing tests**

```bash
@test "safety: uncommitted change during wait tears nothing down" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|1|false|SUCCESS|||u' \
        'MERGED|false||false|SUCCESS|||u'
    echo "echo dirty >>'$WORKTREE_DIR/file'" >"$BATS_TEST_TMPDIR/on-probe-2"
    run "$MERGE_PR" -s
    [ "$status" -eq 1 ]
    [[ "$output" == *"worktree gained uncommitted changes while waiting — nothing torn down"* ]]
    [ -d "$WORKTREE_DIR" ]
}

@test "safety: new commit during wait tears nothing down" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|1|false|SUCCESS|||u' \
        'MERGED|false||false|SUCCESS|||u'
    echo "git -C '$WORKTREE_DIR' -c commit.gpgsign=false commit -q --allow-empty -m mid" \
        >"$BATS_TEST_TMPDIR/on-probe-2"
    run "$MERGE_PR" -s
    [ "$status" -eq 1 ]
    [[ "$output" == *"new commits since the merge started — nothing torn down"* ]]
    run git -C "$REPO_DIR" branch --list feature
    [ -n "$output" ]
}

@test "safety: --force still tears down a worktree dirtied during wait" {
    _queue_setup 'OPEN|false||false|SUCCESS|||u' 'OPEN|true|1|false|SUCCESS|||u' \
        'MERGED|false||false|SUCCESS|||u'
    echo "echo dirty >>'$WORKTREE_DIR/file'" >"$BATS_TEST_TMPDIR/on-probe-2"
    run "$MERGE_PR" --force -s
    [ "$status" -eq 0 ]
    [ ! -d "$WORKTREE_DIR" ]
}

@test "queue: usage mentions the merge queue" {
    run "$MERGE_PR" --help
    [[ "$output" == *"merge queue"* ]]
    [[ "$output" == *"gh pr merge --disable-auto"* ]]
}
```

- [ ] **Step 2: Run the tests and check they fail**

  Run: `bats test/merge-pr.bats -f 'safety:|usage mentions the merge queue'`
  Expected: all 4 fail.

- [ ] **Step 3: Implement**

  - **Before calling `wait_for_merge`**, record
    `pre_wait_head=$(git rev-parse HEAD)`.
  - **After it returns:**
    1. If `HEAD != pre_wait_head`, print `merge-pr: new commits since the merge
       started — nothing torn down` to stderr and exit 1.
    2. If `force` is empty and `git status --porcelain --ignore-submodules=none`
       is non-empty, print `merge-pr: worktree gained uncommitted changes while
       waiting — nothing torn down` to stderr and exit 1.

    The HEAD comparison replaces an unpushed-count re-check. After a merge,
    `delete_branch_on_merge` may have removed the upstream, so `@{u}` can't be
    trusted.
  - **INT trap:** set `trap` on INT for the duration of `wait_for_merge` and
    clear it with `trap - INT` on return. The handler prints this to stderr
    and exits 130:

```text
merge-pr: stopped waiting — nothing torn down. GitHub will still merge the PR on its own.
          Re-run merge-pr to resume waiting, or cancel with: gh pr merge --disable-auto
```

  - **`usage()`:** add a paragraph after the MERGED paragraph. It says that on
    a merge-queue repo, or when `gh pr merge` turns on auto-merge, merge-pr
    waits (polling every 60s, `MERGE_PR_POLL_INTERVAL`) until the PR merges.
    On ejection, failed checks, or a close, it tears nothing down and exits 1.
    It also says that Ctrl-C stops waiting but doesn't cancel the merge
    (`gh pr merge --disable-auto` does).

- [ ] **Step 4: Run the whole file and check it passes**

  Run: `bats test/merge-pr.bats`
  Expected: all pass.

- [ ] **Step 5: Check Ctrl-C by hand.** The bats harness can't deliver SIGINT
  to the wait cleanly.

  1. Set up `_queue_setup`-style stubs in a scratch dir under `$TMPDIR`, with
     the probe always returning `OPEN|true|1|false|SUCCESS|||u`.
  2. Run with `MERGE_PR_POLL_INTERVAL=5` and press Ctrl-C.

  Expected: the hint above, exit code 130, and the worktree still present.

- [ ] **Step 6: Lint and commit**

```bash
precious lint bin/merge-pr test/merge-pr.bats
git add bin/merge-pr test/merge-pr.bats
git commit -m "Re-check worktree safety after the merge-pr wait"
```
