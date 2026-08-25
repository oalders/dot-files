# Docker under the nono sandbox

Background for the `oalders-docker` mixin (`nono/oalders-docker.json`). The
mixin exists to make `docker compose` / `docker buildx` *work* under the
sandbox — it is **not** a security boundary. Read this before reasoning about
what the Docker grants do or don't gate.

## The plugins dir is the whole fix (#1002)

`/usr/libexec/docker/cli-plugins` (read) is the only grant that fixes #1002.
`compose` and `buildx` ship as separate executables in that directory and the
`docker` binary `exec`s them by path, so a session without the read grant gets
`docker: unknown command` for exactly those two — and nothing else about Docker
is broken. It's narrowed to `cli-plugins/` rather than all of
`/usr/libexec/docker`, which also holds daemon-side helpers the CLI never needs.

## The daemon socket is reachable from every session regardless

Landlock's rights model covers path `open()`, not `connect(AF_UNIX)` (verified
against nono 0.73.0), so a grant on `docker.sock` is not what lets the CLI reach
the daemon — and withholding it does not withhold access. Verified empirically
from a live session whose profile did **not** include this mixin:

- `nono why --path /run/docker.sock --op write --profile oalders` →
  `DENIED / path_not_granted`
- …yet `docker ps` succeeds in that same session, reaching the host daemon and
  listing host containers.
- Only `docker compose version` / `docker buildx version` fail there, both with
  `docker: unknown command` — the plugin-dir symptom, nothing socket-shaped.

So the two `allow_file` socket entries (`/var/run/docker.sock`,
`/run/docker.sock`) are **defensive, non-load-bearing**: kept so the profile is
correct-by-construction if nono ever mediates socket `connect()`, and portable
to layouts where `/var/run` is not a symlink to `/run`. `test/nono-profiles.bats`
guards them on that basis and no other.

**Corollary:** `nono why` returns `DENIED` for an access the sandbox actually
permits here, so its verdict is unreliable for sockets, FIFOs, and device nodes.
Verify those empirically.

## Every session is uncontained with respect to Docker

The daemon runs as root *outside* the sandbox, so any session that can talk to
it can do `docker run --privileged -v /:/host` and get host root — which, per
the above, is every session. This is pre-existing; the mixin neither introduces
nor widens it. Tracked with full evidence and candidate mitigations (namespace
shim around `nono run`, a Docker `AuthZ` plugin, rootless Docker) in #1003 —
none fixable in a profile.

## Buildx state is redirected out of `~/.docker`, not granted there (#1004)

Buildx keeps its builders and current-builder pointer under `~/.docker/buildx`
by default. Granting that home path for write would be the mixin's only write to
outlive the session: a session could persist a `remote`-driver builder pointing
at an endpoint it chose and mark it current, and a later **un-sandboxed**
`docker buildx build` on the host would ship that build context (source, `.env`
files) to the endpoint. So `bin/nn` exports `BUILDX_CONFIG="$PWD/.tmp/buildx"`
whenever the resolved profile lists `oalders-docker` — the same redirect it does
for `SERENA_HOME` and `ANSIBLE_LOCAL_TEMP` — and the profile grants no
`~/.docker` write at all. `.tmp` is covered by `--allow-cwd`; the only trade-off
is that builders no longer persist across worktrees. `~/.docker/contexts` is
kept read-only for the same reason.

## Why detection is automatic

Keying on compose files rather than making the mixin opt-in costs no
containment: the escape is already universal (#1003), so an opt-in gate would
gate a privilege sessions already hold and buy nothing but friction. The one
honest caveat is *likelihood*, not capability: a cloned repo's own
`compose.yaml` becomes directly runnable via the exact command its README
suggests, and a compose file can legitimately carry `privileged: true` or
`volumes: ["/:/host"]`. That's the reason to keep treating a strange repo's
compose file as untrusted content. A bare `Dockerfile` is deliberately **not** a
marker: an image-only repo has no compose/buildx workflow to fix.
