# nono config

Wraps Claude Code in the [nono](https://nono.sh/) sandbox. Invoke via `nn` (from `bin/nn`, symlinked to `~/local/bin/nn`).

## Files

- `oalders.json` — nono profile, symlinked to `~/.config/nono/profiles/oalders.json`
- `claude-settings.json` — `{"sandbox": {"enabled": false}}` passed to claude via `--settings`, symlinked to `~/.config/nono/claude-settings.json` (so claude's built-in sandbox stays off while nono does the real work)

## Divergences from the macOS gist

Source: https://gist.github.com/ranguard/66d3a7ea4bba428c0a9ff7d1cba86536

The gist targets macOS (Seatbelt). On Linux (Landlock), several gist entries cause nono to refuse startup with `Landlock deny-overlap is not enforceable`. Landlock is strictly allow-list — it can't express "allow parent X except deny nested Y" the way Seatbelt does.

Dropped from the gist:
- `filesystem.allow: ["~/.config/"]` — overlaps with base `claude-code` denies for browser data (`~/.config/BraveSoftware`, `chromium`, `google-chrome`), shell configs (`fish`), and credentials (`gcloud`, etc.).
- `filesystem.read: ["~/.cache", "~/.local"]` — same class of overlap (e.g. `~/.local/share/keyrings`).
- `~/Library/pnpm/store` — macOS path, no-op on Linux.

Added for Linux:
- `NO_PROXY=localhost,127.0.0.1` reset inside `nn` before claude launches. Nono injects `network.allow_domain` entries into the sandbox's `NO_PROXY`, which makes HTTP clients bypass the nono proxy — and Landlock then blocks the direct TCP. Resetting forces traffic through the proxy, where `allow_domain` actually takes effect.
- `filesystem.allow: ["/tmp/claude-1000"]`. The base profile grants `/tmp` write-only; Claude Code's Bash tool writes output files to `/tmp/claude-$UID/<project>/...` and then reads them back, so the subtree needs r+w. Hardcoded to UID 1000; bump if the account's UID ever changes.
- `filesystem.read_file: ["/etc/gitconfig"]`. The base `git_config` group covers `~/.gitconfig` and `~/.config/git/ignore` but not the system-wide gitconfig. Without it, every `git` invocation fails with `fatal: unknown error occurred while reading the configuration files`.
- `filesystem.read: ["~/.config/gh"]`. Needed for `git push` over HTTPS when gh is the credential helper — gh reads `config.yml` and `hosts.yml` (OAuth token) to answer git's username/password prompt. Read-only is enough for pushes; bump to `allow` if a workflow needs gh to update its own state.
- `nn` passes `--allow $(git rev-parse --git-common-dir)` when cwd is a git worktree. The worktree's `.git` lives under the main repo (`<main>/.git/worktrees/<name>`), outside cwd — so `--allow-cwd` alone leaves git unable to read objects/refs.

## Kernel requirement

`signal_mode: allow_same_sandbox` (and `process_info_mode`) require **Landlock ABI V6**, which landed in Linux **6.12**. Ubuntu 24.04 defaults to 6.8; install `linux-generic-hwe-24.04` to get 6.17+. See `bin/upgrade-to-hwe-kernel.sh`.

## Extending the profile

When claude or an MCP server can't reach something:

1. Confirm the block: `nono why --path <path> --op read --profile oalders` (or `--host <hostname>` for network).
2. Add the minimal grant to `oalders.json`:
   - `filesystem.read` — read-only directories
   - `filesystem.allow` — read+write directories
   - `filesystem.read_file` / `allow_file` — single files
   - `network.allow_domain` — HTTPS hosts (wildcards like `*.github.com` OK)
3. Validate: `nono policy validate ~/.config/nono/profiles/oalders.json`
4. Smoke-test from `/tmp`, not `~/dot-files`. `--allow-cwd` inside this repo triggers the `deny_shell_configs` group's overlap on `~/dot-files/bashrc` etc.: `cd /tmp && nono run --profile oalders --allow-cwd -- true`

**Avoid broad allows on `~`, `~/.config`, `~/.local`, `~/.cache`** — they'll bring back the deny-overlap problem. Prefer specific subpaths.

### Common extensions (paths to add when you need them)

MCP-related grants already in `oalders.json` (from `installer/serena-mcp.sh`, `installer/playwright-mcp.sh`, `installer/chrome.sh`):

- **Serena**: `read` on `~/.local/bin` (uvx wrapper + serena-mcp-server), `~/.local/share/uv` (uv-tool install); `allow` on `~/.serena` (config + logs + memories).
- **Playwright**: `read` on `~/.npm-packages` (playwright-mcp binary), `~/.cache/ms-playwright` (chromium bundle); `allow` on `/dev/shm` (browser IPC).
- **superpowers-chrome**: `read` on `/opt/google/chrome` (browser binary); `allow` on `~/.cache/superpowers` (browser session dirs).

See `claude-nono/Makefile` in this repo for the maximalist reference set.
