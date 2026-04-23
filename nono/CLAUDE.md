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

- **superpowers-chrome** (Chrome DevTools automation): `read` on `/opt/google/chrome`, `/etc/chromium`; maybe `network.open_port` for the CDP debug port.
- **Node/npm MCPs** using global installs: `read` on specific `~/.nvm/versions/node/<v>` paths or `~/.local/lib/node_modules`.
- **Playwright**: `read` on `~/.cache/ms-playwright`, `allow` on `/dev/shm`.
- **Serena** (uv-installed Python venv): `read` on `~/.serena-venv`, `~/.serena`, `~/.cache/uv`.

See `claude-nono/Makefile` in this repo for the maximalist reference set.
