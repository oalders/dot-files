# nono profile rationale

## oalders-docker

- **CLI plugins dir (`/usr/libexec/docker/cli-plugins`, read):** where
  `docker compose` and `docker buildx` actually live.
- **`~/.docker/contexts` and `~/.docker/config.json`, read-only:** a narrow
  slice rather than the whole directory.
- **No home path is granted for write:** buildx state is redirected into the
  worktree via `BUILDX_CONFIG` in `bin/nn` (#1004), so the mixin has no write
  that outlives the session.
- **`allow_file` on the socket paths:** covers `open()` on the socket node.
  Reaching the daemon takes this and `unix_socket`, which cover different
  syscalls.
- **`unix_socket` on the socket paths:** covers `connect(AF_UNIX)`. These
  entries are load-bearing now that nono default-denies AF_UNIX pathname
  connects (the mediation that closes #1003); without them every `connect()` to
  `/run/docker.sock` is blocked.
- **Accepted security tradeoff:** a session that can reach the socket can run
  `docker run --privileged -v /:/host` to get host root, so this mixin is a
  deliberate escape hatch scoped to the sessions that load it, not a global
  grant.
- **Caveat (nono 0.80.0):** the two bullets above assume AF_UNIX mediation is
  on. `nono setup --check-only` reports it off by default
  (`linux.af_unix_mediation = "pathname"` enables it), and `docker ps` reached
  the daemon from a session without this mixin.
- **Net-free:** image pulls run in the daemon outside the sandbox, so nothing
  traverses the session proxy.
