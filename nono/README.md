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

## oalders-playwright-net

- **Hosts:** `cdn.playwright.dev` is the entry point;
  `playwright.download.prss.microsoft.com` and `playwright.azureedge.net` are
  its blob hosts.
- **`storage.googleapis.com`:** `cdn.playwright.dev` 307-redirects the
  `chromium` (Chrome for Testing) build to the `chrome-for-testing-public` GCS
  bucket.
- **GCS scoped to GET/HEAD:** the GCS host is the only download traffic and is
  a signed GET, so the scope drops it as an upload vector.
- **Split from `oalders-playwright`:** so the Chromium-bundle filesystem grant
  can stay net-free.
- **Wider picture, including the host's breadth:**
  [nono/CLAUDE.md](CLAUDE.md#net-free-base-vs-network-siblings)

## oalders-playwright

- **`unix_socket_subtree_bind` on `/tmp/claude-1000/pw-mcp`:** nono blocks
  `bind()` by default, so a bundled-chromium launch dies without this grant for
  Chromium's ProcessSingleton AF_UNIX socket. The path is the MCP's short
  `TMPDIR` base, set by the `installer/playwright-mcp.sh` npx wrapper.
- **Details:**
  [nono/CLAUDE.md](CLAUDE.md#chromiums-processsingleton-socket-bind)

## oalders-codex

- **Accepted security tradeoff:** the grant includes write to `config.toml`,
  which Codex on the host trusts. Details:
  [nono/CLAUDE.md](CLAUDE.md#codex-under-the-sandbox)
- **Contents:** config, ChatGPT login, SQLite state, sessions, tmp.
- **Net-free:** OpenAI hosts live in `oalders-net`.
