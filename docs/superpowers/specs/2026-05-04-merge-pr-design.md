# `bin/merge-pr` design

## Purpose

Provide a single command, run from inside a PR's worktree, that merges the PR
via `gh pr merge` and tears down the local artifacts: worktree, local branch,
and the worktree's tmux session. The tear-down is the part missing from
existing tooling — `bin/remove-worktree` does similar cleanup but kills the
tmux session before doing the worktree removal, which is wrong when invoked
from inside that very session.

## Scope

- The user runs `merge-pr` from inside the worktree's tmux session, with the
  PR's branch checked out. This is the only supported entry point.
- The command does not take a PR number; it always operates on the current
  branch's PR.
- Remote-branch cleanup is out of scope. The user has GitHub's "delete branch
  on merge" repo setting enabled (managed via `bin/gh-delete-branch-on-merge`),
  so the remote branch is removed server-side. We do not pass
  `--delete-branch` to `gh pr merge` because it tries to switch the current
  checkout to the default branch, which fails when that branch is already
  checked out in another worktree.

## Invocation

```
merge-pr [-f|--force] [gh-pr-merge args...]
```

- `-f` / `--force` is consumed by `merge-pr` and means "pass `--force` to
  `git worktree remove`". It may appear anywhere in the argument list and is
  removed before the remaining args are forwarded to `gh pr merge`.
- All remaining args pass through verbatim to `gh pr merge` (e.g.
  `merge-pr --squash`, `merge-pr --rebase -f`).
- `--auto` and `--auto-merge` are refused explicitly. With auto-merge,
  `gh pr merge` exits 0 while the PR stays `OPEN` (waiting for CI), and our
  cleanup would tear down the worktree before the merge actually happens.

## Pre-merge checks

Abort with a clear message before doing any work if any of these fail:

1. We are inside a git work tree (`git rev-parse --is-inside-work-tree`).
2. The current branch is not the PR's base branch. We get the base from
   `gh pr view --json baseRefName -q .baseRefName` (folded into the same
   `gh pr view` call described under "PR state and merge step"). This handles
   repos with non-`main`/`master` defaults (`develop`, `trunk`, etc.).
3. The branch has an upstream (`git rev-parse --abbrev-ref '@{u}'`).
4. There are no unpushed commits
   (`git rev-list --count '@{u}..HEAD'` equals `0`).

We do not check whether the branch is *behind* upstream. Behind-upstream is
fine: the merge happens server-side based on the PR's HEAD on GitHub, and our
local working tree gets thrown away during cleanup either way.

## State capture

Before any mutation, capture:

- `branch` — `git rev-parse --abbrev-ref HEAD`
- `worktree_path` — `git rev-parse --show-toplevel`
- `main_repo` — parent of `git rev-parse --git-common-dir`. (Note:
  `--git-common-dir`, not `--git-dir`. From a worktree, `--git-common-dir`
  always returns the *shared* git dir — the main repo's `.git` — so its
  parent is the main repo. This matches the pattern used in
  `bin/remove-worktree` and `bin/add-worktree`.)
- `session` — the tmux session name to kill, resolved as follows:
  - If `$TMUX` is set, `tmux display-message -p '#S'` (the current session).
  - Else, scan `tmux list-panes -a -F '#{session_name}\t#{pane_start_path}'`
    and pick the first row whose path equals `worktree_path`. We use
    `pane_start_path`, not `session_path` or `pane_current_path`, because it
    reflects the directory tmux launched the pane in (which `add-worktree`
    sets to the worktree dir) and does not drift if the user `cd`s.
  - Else, empty (nothing to kill).

## PR state and merge step

Look up the PR with one call:
`gh pr view --json state,baseRefName -q '[.state, .baseRefName] | @tsv'`.

Use `state` to decide what to do, and `baseRefName` for pre-check #2:

- `OPEN` → run `gh pr merge "$@"`. If it exits non-zero, abort. No cleanup
  has happened yet, so the user is left exactly where they started.
- `MERGED` → skip the merge step and continue to cleanup. This makes
  `merge-pr` idempotent: if cleanup failed on a previous run, re-running the
  command picks up where it left off. `MERGED` is reported regardless of
  merge strategy (squash/rebase/merge).
- Any other state (`CLOSED`, `DRAFT`, etc.) → abort, naming the state.
- `gh pr view` failure (no PR for this branch) → abort.

## Cleanup sequence

After the merge step:

1. `cd "$main_repo"` — required because the next step deletes the directory
   we'd otherwise be standing in.
2. `git worktree remove [--force] "$worktree_path"`. If this fails (typically
   because the worktree is dirty and `--force` was not passed), print:

   > `Worktree has uncommitted changes. Re-run with: merge-pr --force`

   and exit non-zero. The PR is merged at this point; the user can re-run
   `merge-pr --force` and the `MERGED` branch of the state check skips
   straight to cleanup.
3. `git branch -D "$branch"`. Forced because squash- and rebase-merges aren't
   recognized as merged by `git branch -d`.
4. `tmux kill-session -t "$session"` if `session` is non-empty. This is the
   **last** action: when invoked from inside the session being killed, the
   command terminates with the shell. Nothing may follow this line, and the
   exit code is undefined in that path (the shell dies before the script
   returns).

## Why a new script instead of extending existing tools

`bin/remove-worktree` kills the tmux session as its first step. From inside
that session, the script terminates before the worktree/branch removal runs.
Reordering it would be a behaviour change in a tool whose stated purpose is
"remove a worktree by branch name" — not "merge and remove." Keeping
`merge-pr` separate preserves single responsibility and lets each tool stay
focused. (`bin/remove-worktree` also takes a branch name as its argument,
not a worktree path, so its calling convention doesn't fit the from-inside-
the-worktree case anyway.)

## Failure semantics summary

| Stage                   | Failure effect                                                                                       |
| ----------------------- | ---------------------------------------------------------------------------------------------------- |
| Pre-merge checks        | Nothing changed; fix the cause and re-run.                                                           |
| `gh pr view`            | Nothing changed; aborts before any mutation.                                                         |
| `gh pr merge`           | Nothing changed; fix the cause and re-run.                                                           |
| `git worktree remove`   | PR is merged; worktree/branch/session still present. Re-run with `--force` (idempotent via `MERGED`).|
| `git branch -D`         | Possible if the branch is also checked out in another worktree. Manually clean up that worktree first.|
| `tmux kill-session`     | Last step. Exit code undefined when killing the current session; no follow-up code may depend on it. |

## Implementation notes

- Use `set -eu -o pipefail` per repo convention.
- Lint via `precious lint` (shellcheck) and format via `precious tidy`
  (shfmt).
- Manual test matrix: clean worktree merge; dirty worktree without `--force`;
  dirty worktree with `--force`; re-run after a previous failure (PR already
  `MERGED`); run from non-tmux shell; run on the PR's base branch (refuse);
  run with unpushed commits (refuse); run on a closed/draft PR (refuse); run
  with `--auto` (refuse); run with `-f` placed late in the argument list.
