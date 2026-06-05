# nono config

Wraps Claude Code in the [nono](https://nono.sh/) sandbox. Invoke via `nn` (from `bin/nn`, symlinked to `~/local/bin/nn`).

## Files

- `oalders.json` — nono profile, symlinked to `~/.config/nono/profiles/oalders.json`
- `claude-settings.json` — `{"sandbox": {"enabled": false}}` passed to claude via `--settings`, symlinked to `~/.config/nono/claude-settings.json` (so claude's built-in sandbox stays off while nono does the real work)

## Per-project profiles

`nn` walks up from cwd to the git toplevel looking for `.nono/profile.json`. If found, it's passed to `nono run --profile <path>` instead of the global `oalders` profile. Falls back to `oalders` when no local profile exists, or stays at cwd-only when not in a git repo.

Project-local profiles can `"extends": "oalders"` to layer additional grants on top, or stand alone for a tighter sandbox.

## Sibling profiles

`oalders.json` is a lean composition root. Tool- and stack-specific grants live in standalone sibling profiles (`oalders-<topic>.json`) that do **not** `extends: "oalders"` — they're meant to be composed via `extends: [...]`, not stacked into a single inheritance chain.

`extends` accepting a list comes from nono PR #399; sibling profiles must therefore live as named profiles in `~/.config/nono/profiles/` so the lookup resolves.

### Always-on (mixed in via `oalders.json`'s own `extends`)

These are global infrastructure — MCP servers Claude relies on, and their runtimes — so they go in `oalders.json`'s `extends` list rather than per-repo detection.

| Profile             | Owns                                                                                   |
| ------------------- | -------------------------------------------------------------------------------------- |
| `oalders-uv`        | `~/.local/share/uv` (uv runtime — used by `uvx` and `uv tool install`)                 |
| `oalders-serena`    | `~/.serena` (serena MCP config/logs/memories)                                          |
| `oalders-playwright`| `~/.cache/ms-playwright` (Chromium bundle), `/dev/shm` (browser IPC)                   |
| `oalders-chrome`    | `/opt/google/chrome` (browser binary), `~/.cache/superpowers` (browser session dirs)   |

### Project-detected (mixed in by `nn`)

`nn` scans the repo top when no `.nono/profile.json` exists yet, and writes a wrapper composing `oalders` with any matching sibling.

| Profile         | Markers at repo root                  | Owns                                                                               |
| --------------- | ------------------------------------- | ---------------------------------------------------------------------------------- |
| `oalders-perl`  | `cpanfile`, `Makefile.PL`, `dist.ini` | plenv (`~/.plenv`), local::lib (`~/perl5`), Dist::Zilla (`~/.dzil`, `~/dot-files/dzil`), prove (`~/.proverc`), CPAN/MagPie network, XS system C headers (`/usr/include`, `/usr/local/include`) |
| `oalders-node`  | `package.json`                        | `*.npmjs.org`, `registry.npmjs.org` (npm registry network access for installs)     |
| `oalders-go`    | `go.mod`                              | Go toolchain (`go_runtime` group), build/module/lint caches (`~/.cache/go-build`, `~/.cache/golangci-lint`, `~/go/pkg/mod`), module proxy + checksum DB (`proxy.golang.org`, `sum.golang.org`), and cgo system headers (`/usr/include`, `/usr/local/include`, `/opt/homebrew/include`, pkg-config dirs, `/Library/Developer/CommandLineTools`) |
| `oalders-hugo`  | `hugo.toml` / `hugo.yaml` / `hugo.json`, or `config.toml` + `themes/` | Hugo cache (`~/.cache/hugo_cache`). When Hugo matches, `nn` also appends `oalders-snap` to the mixin list because Hugo on Linux is typically snap-installed. |
| `oalders-snap`  | (no markers of its own — `nn` appends it alongside any snap-backed sibling like `oalders-hugo`) | Reads for snap-confined binaries: `/snap`, `/var/lib/snapd`, `/etc/fstab` (snapd's startup checks parse the mount table). |

Example wrapper for a Node + Perl repo (`package.json` + `cpanfile` at top):

```json
{"extends": ["oalders", "oalders-perl", "oalders-node"]}
```

### Opt-in only (no auto-detection)

These siblings are symlinked into `~/.config/nono/profiles/` but aren't mixed in by `oalders.json` or `bin/nn` — a repo that wants them lists them in its own `.nono/profile.json`. Use when the tool's marker would produce too many false positives (e.g. `*.tf` files can show up in non-IaC repos as fixtures), or the use case is rare enough that auto-detect overhead isn't worth it.

| Profile             | Owns                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------- |
| `oalders-terraform` | `~/.terraform.d`, `~/.terraformrc` (read-only); `registry.terraform.io` (network)     |

Opt-in via per-repo `.nono/profile.json`:

```json
{"extends": ["oalders", "oalders-terraform"]}
```

### Adding a new sibling

1. Write `nono/oalders-<topic>.json` standalone (no `extends`).
2. Add a symlink line in `installer/symlinks.sh` for `~/.config/nono/profiles/oalders-<topic>.json`.
3. If it should be always-on, append `"oalders-<topic>"` to `oalders.json`'s `extends`. If it's per-project, add a detection block in `bin/nn` that appends `"oalders-<topic>"` to `mixins`.

### Wrapper lifecycle

The wrapper at `<toplevel>/.nono/profile.json` is generated only once per repo (when that file is absent). To re-detect after the project changes stacks — e.g. a `cpanfile` was added to a previously bare repo — `rm .nono/profile.json` and re-run `nn`. Hand-authored `.nono/profile.json` files are never overwritten; the walk-up finds them first and exits before detection runs.

`.nono/profile.json` is not gitignored globally — choose per repo whether to commit it (share team sandbox config) or add `.nono/profile.json` to that repo's `.gitignore`.

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
- `SERENA_HOME=$PWD/.serena-home` set inside `nn` before claude launches. Serena's `SerenaConfig.from_config_file()` reads every entry in `~/.serena/serena_config.yml`'s `registered_projects` on startup; if any path is outside the sandbox the MCP server crashes with `Permission denied` before the requested project is even activated. Pointing `SERENA_HOME` at a worktree-local dir (covered by `--allow-cwd`) gives each session a fresh, empty registry. Trade-off: serena's memories/logs no longer persist across worktrees — acceptable since the registry pollution was the actual problem and per-worktree scoping is desirable anyway.
- `nono/serena_config.yml` is the seed config that `nn` copies into `$PWD/.serena-home/serena_config.yml` on every launch. It sets `web_dashboard: false` (Landlock blocks the dashboard's port-bind walk from 24282 upward, crashing serena with `No free ports found starting from 24282`) and `projects: []` (re-enforced each launch so the per-worktree registry can never accumulate stale entries). Single source of truth for both settings; everything else falls back to serena defaults. Once this is in place, the `~/.serena` grant in `oalders-serena.json` is dead weight for sandboxed sessions — left in for now since non-sandboxed tooling may still touch it.

## Why `network_profile` is set to `null`

The `claude-code` network bundle (`network.network_profile`) sets up nono's reverse proxy and injects `ANTHROPIC_BASE_URL=http://127.0.0.1:<port>/anthropic`. The `anthropic` route demands `env://ANTHROPIC_API_KEY`; Max/OAuth users have no API key, so the proxy returns `407 Proxy Authentication Required` with body `{"error":"Proxy Authentication Required"}`. The startup `WARN ... requests will proceed without credential injection` is misleading — actual behavior is hard-reject.

Surfaced 2026-04-30 after claude auto-updated to a version that respects `ANTHROPIC_BASE_URL`. Earlier claude went to `api.anthropic.com` directly and tunneled through `HTTPS_PROXY`, dodging the intercept.

Workaround: set `"network_profile": null` in `oalders.json` and replace the curated bundle with an explicit `allow_domain` list (Anthropic, GitHub, npm, Go module proxy). The explicit `null` is the documented opt-out pattern — see nono's `docs/cli/clients/claude-code.mdx` (`claude-code-netopen` example). Today the parent `claude-code` profile doesn't set `network_profile`, so omitting the field would also work, but `null` is defensive against a future nono release adding it back.

Upstream to watch:
- https://github.com/always-further/nono/issues/793 — exec-sourced credentials (covers `apiKeyHelper` shape)
- https://github.com/always-further/nono/issues/770 — refreshable credential backend
- https://github.com/always-further/nono/issues/724 — 3rd-party provider profiles

Re-test on each nono release: temporarily flip `"network_profile": null` to `"claude-code"` in `oalders.json` and run from `$TMPDIR`:
```
cd "${TMPDIR:-/tmp}" && nono run --profile oalders --allow-cwd -- curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST "$ANTHROPIC_BASE_URL/v1/messages" -d '{}'
```
Non-407 means the route became OAuth-aware and you can re-adopt the curated bundle. While `network_profile` is null, the `NO_PROXY` reset in `bin/nn` is vestigial (no proxy is started) but harmless — it re-becomes load-bearing the moment the curated bundle is restored.

## Kernel requirement

`signal_mode: allow_same_sandbox` (and `process_info_mode`) require **Landlock ABI V6**, which landed in Linux **6.12**. Ubuntu 24.04 defaults to 6.8; install `linux-generic-hwe-24.04` to get 6.17+. See `bin/upgrade-to-hwe-kernel.sh`.

## Extending the profile

When claude or an MCP server can't reach something:

1. Confirm the block: `nono why --path <path> --op read --profile oalders` (or `--host <hostname>` for network).
2. Add the minimal grant to the right file:
   - **Stack-specific** (only useful in Perl/Node/Go/etc. projects) → the matching `oalders-<stack>.json` sibling. If the stack doesn't have a sibling yet, see "Language sibling profiles" above for how to add one.
   - **Cross-cutting** (needed across all projects) → `oalders.json`.

   Grant kinds:
   - `filesystem.read` — read-only directories
   - `filesystem.allow` — read+write directories
   - `filesystem.read_file` / `allow_file` — single files
   - `network.allow_domain` — HTTPS hosts (wildcards like `*.github.com` OK)
3. Validate: `nono policy validate ~/.config/nono/profiles/<file>.json`
4. Smoke-test from `$TMPDIR`, not `~/dot-files`. `--allow-cwd` inside this repo still triggers the `deny_shell_configs` group's overlap on the remaining shell configs (`bash_profile`, `profile`, etc.): `cd "${TMPDIR:-/tmp}" && nono run --profile oalders --allow-cwd -- true`. `bashrc` itself is exempted via `filesystem.bypass_protection` so `nono shell` and `nono run`-with-rc don't error on `~/.bashrc` → `~/dot-files/bashrc` — safe here because this repo is public and scanned for secrets.

**Avoid broad allows on `~`, `~/.config`, `~/.local`, `~/.cache`** — they'll bring back the deny-overlap problem. Prefer specific subpaths.

### Cross-cutting bits that stay in `oalders.json`

These don't belong to any single tool or stack, so they live in the base:

- `read` on `~/.local/bin` (uvx wrapper, serena-mcp-server, generic user-installed scripts — used across siblings) and `~/.npm-packages` (npm-installed binaries: playwright-mcp consumer + standalone npx use).
- `read` on `~/dot-files/bin` (npx wrapper that intercepts `@playwright/mcp@latest` so it sits ahead of `~/dot-files/node_modules/.bin/npx` in PATH).
- `read` on `~/dot-files/node_modules` (prettier and other dev-tool binaries; `bashrc` puts `~/dot-files/node_modules/.bin` on PATH ahead of `/usr/bin`, so the dir must be readable or `npm`, `prettier`, etc. fail with `Permission denied` before they run). Paired with `NPM_CONFIG_CACHE=$PWD/.tmp/cache/npm` in `bin/nn` to keep npm's cache off the read-only `~/.npm` path.
- `read` on `~/.config/gh` (git push over HTTPS via gh credential helper).
- `read_file` on `/etc/gitconfig` (system-wide gitconfig outside the base `git_config` group's coverage).
- `read_file` on `~/dot-files/claude/CLAUDE.md` (the global Claude Code instructions). `~/.claude/CLAUDE.md` is a symlink to this path; without the grant the harness can't follow the symlink and none of the global instructions load in sandboxed sessions. Single-file grant rather than a `read` on `~/dot-files/claude/` — `statusline-command.sh` is the only other file under there the sandbox needs, and it's already granted below.
- `read_file` on `~/dot-files/claude/statusline-command.sh` (the Claude Code statusline script, run sandboxed as a child of claude; `bin/nn` injects the matching `statusLine` block into the session settings since the sandbox can't read `~/.claude/settings.json`).
- `bypass_protection` on `~/.bashrc` → `~/dot-files/bashrc` (so `nono shell` and rc-loading don't trip the `deny_shell_configs` overlap; safe since this repo is public and scanned for secrets).

See `claude-nono/Makefile` in this repo for the maximalist reference set.
