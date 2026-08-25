# docker-teardown: design and rationale

`bin/docker-teardown` removes the docker artifacts a worktree session leaves
behind so `git worktree remove` (called by `bin/merge-pr` and
`bin/remove-worktree`) can delete the tree cleanly. This is the relocated "why"
behind the script; the script keeps only orienting one-liners and points here.

## Why it exists

Containers are children of the docker daemon, not of the tmux pane or the
nono/claude/serena process tree. So neither `kill-worktree-procs` (which walks
`/proc` cwd + nono/claude ancestry) nor `tmux kill-session` touches them. Left
behind, they keep running with the worktree deleted.

## Provable ownership — never a bare `docker ps` sweep

A container is a target only when its ownership of *this* worktree is provable:

- **compose**: the `com.docker.compose.project.working_dir` label is the
  worktree dir or a path under it;
- **bin/dev**: the container name is exactly `<basename $wt>-<branch>`, which is
  how `bin/dev` derives it (repo basename + branch, `/` → `-`).

Ad-hoc `docker run` containers carry no such handle and are left alone, matching
the "minimize false positives" bias of the other teardown helpers.

## Network sweep

Empty compose networks are swept under the same provable-ownership bar. A
network is removed only when BOTH hold: (a) its `com.docker.compose.project`
label matches a project this worktree owns — a project name derived from a
matched container, or the compose default project (the worktree dir basename
normalized as compose stores it) — AND (b) it has zero attached containers. The
zero-attachment guard keeps a shared/in-use network safe and makes re-runs a
no-op.

### Same-basename collision (bounded, accepted)

Two worktrees sharing a dir basename — the same repo checked out twice, or the
same basename across different repos — resolve to the SAME compose default
project name, so tearing down one may sweep a network the sibling also uses. The
zero-attachment guard bounds this: only an EMPTY network is ever removed, and
compose recreates `<project>_default` on the sibling's next `up`.

### Why networks are removed but volumes kept

A compose network is cheap to recreate (the next `up` rebuilds
`<project>_default`); a session volume holds state (bin/dev's Claude history)
that no `up` would bring back. Leaked empty networks are also a real hazard:
they accumulate until docker's default address pool is subnetted out and
`compose up` fails everywhere with "all predefined address pools have been fully
subnetted".

### Why not `docker network prune`

A bare prune would also delete empty hand-created `external:` networks, which
compose does NOT recreate. The targeted, label-scoped sweep touches only this
worktree's own networks.

## Ownership reclaim

A compose service that bind-mounts a worktree directory (a database data dir, a
certbot state dir) runs as root inside the container and creates those files as
root on the host. `git worktree remove --force` then dies with "Permission
denied" partway through — and by then it has already removed `.git` and
unregistered the worktree, leaving an orphaned tree `git worktree list` no
longer knows about. The fix mirrors the cause: a throwaway root container with
the worktree bind-mounted chowns the offending paths back to us — no sudo, no
password prompt. It runs even when no containers matched, since the writer may
have been removed days ago or by a previous run.
