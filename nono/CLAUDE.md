# nono config

Wraps Claude Code in the [nono](https://nono.sh/) sandbox. Invoke via `nn` (from `bin/nn`, symlinked to `~/local/bin/nn`).

## Files

- `oalders.json` — nono profile composition root (`extends: [oalders-core, oalders-net, oalders-playwright-net]`), symlinked to `~/.config/nono/profiles/oalders.json`
- `oalders-core.json` — net-free shared base (always-on MCP/runtime siblings, security policy, cross-cutting filesystem grants), symlinked to `~/.config/nono/profiles/oalders-core.json`
- `oalders-net.json` — all outbound network rules for the default chain (curated `allow_domain`, `open_port`, `network_profile: null`), symlinked to `~/.config/nono/profiles/oalders-net.json`
- `oalders-playwright-net.json` — Playwright browser-download CDN hosts for the default chain (paired with the net-free `oalders-playwright`), symlinked to `~/.config/nono/profiles/oalders-playwright-net.json`
- `oalders-open.json` — permissive opt-in profile (`extends: [oalders-core]`, no `oalders-net`): full outbound network with the same filesystem lockdown as `oalders`, symlinked to `~/.config/nono/profiles/oalders-open.json`
- `claude-settings.json` — `{"sandbox": {"enabled": false}}` passed to claude via `--settings`, symlinked to `~/.config/nono/claude-settings.json` (so claude's built-in sandbox stays off while nono does the real work)

## Per-project profiles

`nn` walks up from cwd to the git toplevel looking for `.nono/profile.json`. If found, it's passed to `nono run --profile <path>` instead of the global `oalders` profile. Falls back to `oalders` when no local profile exists, or stays at cwd-only when not in a git repo.

Project-local profiles can `"extends": "oalders"` to layer additional grants on top, or stand alone for a tighter sandbox.

## Sibling profiles

`oalders.json` is a lean composition root. Tool- and stack-specific grants live in standalone sibling profiles (`oalders-<topic>.json`) that do **not** `extends: "oalders"` — they're meant to be composed via `extends: [...]`, not stacked into a single inheritance chain.

`extends` accepting a list comes from nono PR #399; sibling profiles must therefore live as named profiles in `~/.config/nono/profiles/` so the lookup resolves.

### Net-free base vs. network siblings

`oalders` is now `{"extends": ["oalders-core", "oalders-net", "oalders-playwright-net"]}`:

- **`oalders-core`** holds the always-on siblings, the `security` block, and the cross-cutting `filesystem` grants — and **no `network`**.
- **`oalders-net`** holds *all* cross-cutting outbound rules: the curated `allow_domain` list, `open_port`, the defensive `network_profile: null`, and uv's PyPI domains.
- **`oalders-playwright-net`** holds the Playwright browser-download hosts. It pairs with the always-on net-free `oalders-playwright` (Chromium-bundle filesystem grant) the same way `oalders-perl-net` pairs with `oalders-perl` — kept separate so the filesystem grant stays net-free, but composed into the default `oalders` chain (not `oalders-core`) so the permissive profiles don't inherit its allowlist. Note `storage.googleapis.com` in the list: Playwright's `chromium` is "Chrome for Testing", and `cdn.playwright.dev` 307-redirects that build to the `chrome-for-testing-public` Google Cloud Storage bucket — so `playwright install chromium` needs the GCS host as well as the three Playwright CDN hosts. It's broad (fronts every public GCS bucket; not narrowable to a subdomain because the download is path-style `storage.googleapis.com/<bucket>/...`), the price of in-sandbox `chromium` installs.

The rule that forces this split: nono's `extends` is append-only, and **any** `allow_domain` anywhere in the chain flips nono into proxy allowlist mode (default-deny outbound). There is no way to remove an inherited domain. So every grant sibling (filesystem/runtime) is kept net-free, and all domains/ports live in dedicated `*-net` siblings. A profile that needs open network — like `oalders-perl-test` — composes only net-free grants and adds no `*-net`, leaving outbound and localhost ports unrestricted.

### Always-on (mixed in via `oalders-core`'s `extends`)

These are global infrastructure — MCP servers Claude relies on, and their runtimes — so they go in `oalders-core`'s `extends` list (which `oalders` always pulls in) rather than per-repo detection.

| Profile             | Owns                                                                                   |
| ------------------- | -------------------------------------------------------------------------------------- |
| `oalders-uv`        | `~/.local/share/uv` (uv runtime — used by `uvx` and `uv tool install`). Net-free; PyPI domains live in `oalders-net`. |
| `oalders-serena`    | `~/.serena` (serena MCP config/logs/memories)                                          |
| `oalders-playwright`| `~/.cache/ms-playwright` (host Chromium bundle, **read-only**), `/dev/shm` (browser IPC). `bin/nn` sets `PLAYWRIGHT_BROWSERS_PATH` so every worktree and the in-sandbox MCP share the one bundle instead of re-downloading ~265 MB each (#975). Read-only so a session executes browsers but can never poison the shared bundle; seeded/updated on the host by `installer/playwright-mcp.sh`. An in-sandbox `playwright install` for an unseeded build fails loudly against the read-only path — the cue to refresh on the host. Net-free; CDN hosts live in the paired `oalders-playwright-net`. |
| `oalders-chrome`    | `/opt/google/chrome` (browser binary), `~/.cache/superpowers` (browser session dirs), `~/.config/google-chrome/Crash Reports` (crashpad database — grant + `bypass_protection`; see "superpowers-chrome (full Chrome) under the sandbox") |

### Project-detected (mixed in by `nn`)

`nn` scans the repo top when no `.nono/profile.json` exists yet, and writes a wrapper composing `oalders` with any matching sibling.

| Profile         | Markers at repo root                  | Owns                                                                               |
| --------------- | ------------------------------------- | ---------------------------------------------------------------------------------- |
| `oalders-perl`  | `cpanfile`, `Makefile.PL`, `dist.ini` | plenv (`~/.plenv`), local::lib (`~/perl5`), Dist::Zilla (`~/.dzil`, `~/dot-files/dzil`), prove (`~/.proverc`), XS system C headers (`/usr/include`, `/usr/local/include`). Net-free; CPAN/MetaCPAN/MagPie network is in the paired `oalders-perl-net` (appended alongside it by `nn`). |
| `oalders-node`  | `package.json`                        | `*.npmjs.org`, `registry.npmjs.org` (npm registry network access for installs)     |
| `oalders-go`    | `go.mod`                              | Go toolchain (`go_runtime` group), build/module/lint caches (`~/.cache/go-build`, `~/.cache/golangci-lint`, `~/go/pkg/mod`), module proxy + checksum DB (`proxy.golang.org`, `sum.golang.org`), and cgo system headers (`/usr/include`, `/usr/local/include`, `/opt/homebrew/include`, pkg-config dirs, `/Library/Developer/CommandLineTools`) |
| `oalders-docker` | `docker-compose.yml` / `docker-compose.yaml` / `compose.yml` / `compose.yaml` | `/usr/libexec/docker/cli-plugins` (read) — the only load-bearing grant, the fix for #1002 (compose/buildx are CLI plugins that fail `docker: unknown command` without it). `~/.docker` narrowed to `contexts/` + `config.json` (read), no write; buildx state redirected to the worktree via `BUILDX_CONFIG` (#1004). The two `docker.sock` `allow_file` entries are defensive only. Net-free (the daemon pulls images, outside the sandbox). A bare `Dockerfile` is **not** a marker. **The mixin makes docker *work*, not a security boundary — see [docs/nono/docker-under-the-sandbox.md](../docs/nono/docker-under-the-sandbox.md).** |
| `oalders-hugo`  | `hugo.toml` / `hugo.yaml` / `hugo.json`, or `config.toml` + `themes/` | Hugo cache (`~/.cache/hugo_cache`). When Hugo matches, `nn` also appends `oalders-snap` to the mixin list because Hugo on Linux is typically snap-installed, and — if the host is on a tailnet — opens Hugo's serve ports over the tailscale IP (see §2c). |
| `oalders-snap`  | (no markers of its own — `nn` appends it alongside any snap-backed sibling like `oalders-hugo`) | Reads for snap-confined binaries: `/snap`, `/var/lib/snapd`, `/etc/fstab` (snapd's startup checks parse the mount table). |

Example wrapper for a Node + Perl repo (`package.json` + `cpanfile` at top):

```json
{"extends": ["oalders", "oalders-perl", "oalders-node"]}
```

#### `oalders-docker`: the socket grants contain nothing

Rules (full evidence and rationale:
[docs/nono/docker-under-the-sandbox.md](../docs/nono/docker-under-the-sandbox.md)):

- **The plugins-dir read is the whole fix (#1002).** compose/buildx are CLI
  plugins the `docker` binary `exec`s by path; without the read they fail
  `docker: unknown command`. Nothing else about Docker is broken.
- **The daemon socket is reachable from every session regardless.** Landlock
  covers path `open()`, not `connect(AF_UNIX)` (nono 0.73.0), so the two
  `docker.sock` `allow_file` entries are defensive only. Corollary: `nono why`
  is unreliable for sockets/FIFOs/device nodes — verify those empirically.
- **Every session is uncontained w.r.t. Docker.** The daemon runs as root
  outside the sandbox, so any session reaching it has host root (#1003). The
  mixin neither introduces nor widens this.
- **Buildx state is redirected to the worktree, not granted in `~/.docker`
  (#1004)** — `bin/nn` sets `BUILDX_CONFIG=$PWD/.tmp/buildx` to avoid a
  host-side write that could outlive the session.
- **Detection is automatic** because the escape is already universal, so an
  opt-in gate would buy only friction. It raises *likelihood* not *capability* —
  keep treating a strange repo's compose file as untrusted. A bare `Dockerfile`
  is still not a marker.

### Opt-in only (no auto-detection)

These siblings are symlinked into `~/.config/nono/profiles/` but aren't mixed in by `oalders.json` or `bin/nn` — a repo that wants them lists them in its own `.nono/profile.json`. Use when the tool's marker would produce too many false positives (e.g. `*.tf` files can show up in non-IaC repos as fixtures), or the use case is rare enough that auto-detect overhead isn't worth it.

| Profile             | Owns                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------- |
| `oalders-ansible`   | `~/.local/share/pipx/venvs/ansible` (read; the full `ansible` pipx package's venv, which `~/.local/bin/ansible*` symlink into — the read grant is what lets them run; **not** `ansible-core`, which is a different pipx package name this setup doesn't use, see #991) and `~/.ansible/collections` (read; user-installed Galaxy collections install outside the venv). Filesystem only, no network — SSH egress to deploy targets stays out of scope. When a session's profile lists this mixin in its `extends`, `bin/nn` also sets `ANSIBLE_LOCAL_TEMP` to the worktree-local `.tmp` (covered by `--allow-cwd`) so ansible's controller `local_tmp` — where it stages module payloads, which can carry vault-decrypted secrets — needs no `~/.ansible/tmp` write grant and stays off the shared `/tmp/claude-<uid>` scratch base other concurrent sandboxes can read. (`local_tmp` holds files, not sockets, so the `sun_path` limit that forces the browser onto a short base doesn't apply; SSH ControlPersist sockets are a separate setting, `control_path_dir`/`~/.ansible/cp`, and out of scope for this net-free, egress-free mixin.) Opt-in because ansible is deploy-host tooling rarely used inside dev repos. |
| `oalders-terraform` | `~/.terraform.d`, `~/.terraformrc` (read-only); `registry.terraform.io` (network)     |
| `oalders-perl-test` | Open outbound network + unrestricted localhost ports (no `allow_domain`/`open_port` in its chain, so `nono why` likewise reports `network_allowed`), with `oalders-core` + `oalders-perl` grants and the full filesystem lockdown. For CPAN test suites needing live network or `Test::TCP`-style ephemeral ports. |
| `oalders-open`      | Open outbound network (no `allow_domain` in its chain, so `nono why` reports `network_allowed`), with only `oalders-core` grants and the full filesystem lockdown. General-purpose permissive profile for non-Perl sessions that genuinely need unrestricted outbound. |

Opt-in via per-repo `.nono/profile.json`:

```json
{"extends": ["oalders", "oalders-terraform"]}
```

`oalders-perl-test` and `oalders-open` are invoked directly rather than via a per-repo wrapper, because they intentionally drop the network/port restrictions a wrapper extending `oalders` would re-impose:

```
nn --profile oalders-perl-test
nn --profile oalders-open
```

### Adding a new sibling

1. Write `nono/oalders-<topic>.json` standalone (no `extends`).
2. Add a symlink line in `installer/symlinks.sh` for `~/.config/nono/profiles/oalders-<topic>.json`.
3. If it should be always-on, append `"oalders-<topic>"` to `oalders-core.json`'s `extends` (net-free grants); a sibling that adds outbound domains/ports instead folds into `oalders-net.json` (or is added to `oalders.json`'s `extends` alongside `oalders-net`). If it's per-project, add a detection block in `bin/nn` that appends `"oalders-<topic>"` to `mixins`.

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
- `filesystem.unix_socket_dir: ["/tmp/tmux-1000"]`. Lets a sandboxed process `connect()` to the tmux control socket (session-name capture), which nono 0.74.0 otherwise blocks. **Do not pin back to v0.73.0** (capture worked there only via a fail-open gap). **Security tradeoff, accepted (#1022):** this also permits `tmux send-keys` into any pane on the server — a sandbox escape into our own unsandboxed panes; it lives in `oalders-core`, so every session inherits it. UID 1000 hardcoded. Why `unix_socket_dir` over the alternatives, the recursive-grant caveat, and the full tradeoff: [docs/nono/tmux-socket-grant.md](../docs/nono/tmux-socket-grant.md).
- `filesystem.read_file: ["/etc/gitconfig"]`. The base `git_config` group covers `~/.gitconfig` and `~/.config/git/ignore` but not the system-wide gitconfig. Without it, every `git` invocation fails with `fatal: unknown error occurred while reading the configuration files`.
- `filesystem.read: ["~/.config/gh"]`. Needed for `git push` over HTTPS when gh is the credential helper — gh reads `config.yml` and `hosts.yml` (OAuth token) to answer git's username/password prompt. Read-only is enough for pushes; bump to `allow` if a workflow needs gh to update its own state.
- `nn` passes `--allow $(git rev-parse --git-common-dir)` when cwd is a git worktree. The worktree's `.git` lives under the main repo (`<main>/.git/worktrees/<name>`), outside cwd — so `--allow-cwd` alone leaves git unable to read objects/refs.
- `SERENA_HOME=$PWD/.serena-home` set inside `nn` before claude launches. Serena's `SerenaConfig.from_config_file()` reads every entry in `~/.serena/serena_config.yml`'s `registered_projects` on startup; if any path is outside the sandbox the MCP server crashes with `Permission denied` before the requested project is even activated. Pointing `SERENA_HOME` at a worktree-local dir (covered by `--allow-cwd`) gives each session a fresh, empty registry. Trade-off: serena's memories/logs no longer persist across worktrees — acceptable since the registry pollution was the actual problem and per-worktree scoping is desirable anyway.
- `nono/serena_config.yml` is the seed config that `nn` copies into `$PWD/.serena-home/serena_config.yml` on every launch. It sets `web_dashboard: false` (Landlock blocks the dashboard's port-bind walk from 24282 upward, crashing serena with `No free ports found starting from 24282`) and `projects: []` (re-enforced each launch so the per-worktree registry can never accumulate stale entries). Single source of truth for both settings; everything else falls back to serena defaults. Once this is in place, the `~/.serena` grant in `oalders-serena.json` is dead weight for sandboxed sessions — left in for now since non-sandboxed tooling may still touch it.

## Why `network_profile` is set to `null`

`oalders-net.json` sets `"network_profile": null` and lists outbound rules as an explicit `allow_domain` set (Anthropic, GitHub, npm, Go module proxy) instead of the curated `claude-code` bundle. That bundle's reverse proxy hard-rejects Max/OAuth users (no API key → `407`), despite a misleading "proceeds without credential injection" warning. **Do not restore the curated bundle without re-testing** — the reject returns.

Why the bundle rejects, the re-test command to run on each nono release, and the upstream issues to watch: [docs/nono/network-profile-null.md](../docs/nono/network-profile-null.md).

## superpowers-chrome (full Chrome) under the sandbox

The `superpowers-chrome` MCP (opt-in via `nn --chrome`) drives the **full** Google Chrome build, not Playwright's headless shell. `bin/nn` and `oalders-chrome.json` fix two launch failures, gated on `--chrome` (#970):

- **Crashpad crash DB.** Full Chrome SIGTRAPs on startup (exit 133) when denied `~/.config/google-chrome/Crash Reports`. `oalders-chrome.json` grants and `bypass_protection`s **only** that subdir (leaving `Default/` denied), and `bin/nn` pre-creates it (a grant can't create the dir). The Playwright MCP hits the same crash and is fixed differently — its `bin/npx` wrapper drives Playwright's bundled Chromium (`--browser chromium --headless`), where the denied dir is non-fatal.
- **`Socket path too long`.** In a deep worktree, Chromium's `SingletonSocket` under `TMPDIR=$PWD/.tmp` overruns the ~108-char `sun_path` limit. The `bin/npx` wrapper redirects **just the browser's** `TMPDIR` to the short `/tmp/claude-<uid>` base.

Details (why crashpad flags don't help, exact symptoms, the Chrome-for-Testing switch): [docs/nono/chrome-under-the-sandbox.md](../docs/nono/chrome-under-the-sandbox.md).

### Ports `bin/nn` opens

Every non-default grant uses repeated `nono run --open-port` (localhost connect + listen), scoped so idle sandboxes keep the port closed. Rationale for each — the name-only `extends` limit that forces the CLI flag, and per-feature scoping — is in [docs/nono/chrome-under-the-sandbox.md](../docs/nono/chrome-under-the-sandbox.md).

| Port(s) | Opened when | For |
| --- | --- | --- |
| `80`, `5000`, `5001`, `8080` | always (default chain) | `oalders-net`'s baseline `open_port` |
| `9222` | `--chrome` | Chrome DevTools endpoint (`CHROME_WS_PORT=9222`) the superpowers-chrome MCP drives |
| `9323`–`9342` | `playwright_enabled` (e2e markers or `--playwright`) | Playwright HTML report / trace viewer (`9323`) + preview / `webServer` (`9324`–`9342`); serve within this range |
| `1313`–`1316` | Hugo detected **and** host has a tailscale IPv4 | `hugo server` bound to `$TAILSCALE_IP` (also exported), reachable over the tailnet |

## Kernel requirement

`signal_mode: allow_same_sandbox` (and `process_info_mode`) require **Landlock ABI V6**, which landed in Linux **6.12**. Ubuntu 24.04 defaults to 6.8; install `linux-generic-hwe-24.04` to get 6.17+. See `bin/upgrade-to-hwe-kernel.sh`.

## Extending the profile

When claude or an MCP server can't reach something:

1. Confirm the block: `nono why --path <path> --op read --profile oalders` (or `--host <hostname>` for network).
2. Add the minimal grant to the right file:
   - **Stack-specific** (only useful in Perl/Node/Go/etc. projects) → the matching `oalders-<stack>.json` sibling. If the stack doesn't have a sibling yet, see "Language sibling profiles" above for how to add one.
   - **Cross-cutting** (needed across all projects) → `oalders-core.json` (the net-free base). New network domains/ports → `oalders-net.json`.

   Grant kinds:
   - `filesystem.read` — read-only directories (also lets binaries inside run: nono models only read/write, with no separate exec right, so the read grant is what makes a tool's venv/bin dir executable)
   - `filesystem.allow` — read+write directories
   - `filesystem.read_file` / `allow_file` — single files
   - `network.allow_domain` — HTTPS hosts (wildcards like `*.github.com` OK)
3. Validate: `nono policy validate ~/.config/nono/profiles/<file>.json`
4. Smoke-test from `$TMPDIR`, not `~/dot-files`. `--allow-cwd` inside this repo still triggers the `deny_shell_configs` group's overlap on the remaining shell configs (`bash_profile`, `profile`, etc.): `cd "${TMPDIR:-/tmp}" && nono run --profile oalders --allow-cwd -- true`. `bashrc` itself is exempted via `filesystem.bypass_protection` so `nono shell` and `nono run`-with-rc don't error on `~/.bashrc` → `~/dot-files/bashrc` — safe here because this repo is public and scanned for secrets.

**Avoid broad allows on `~`, `~/.config`, `~/.local`, `~/.cache`** — they'll bring back the deny-overlap problem. Prefer specific subpaths.

### Cross-cutting bits that live in `oalders-core.json`

These don't belong to any single tool or stack, so they live in `oalders-core` (the net-free base that `oalders` always extends):

- `read` on `~/.local/bin` (uvx wrapper, serena-mcp-server, generic user-installed scripts — used across siblings) and `~/.npm-packages` (npm-installed binaries: playwright-mcp consumer + standalone npx use).
- `read` on `~/dot-files/bin` (npx wrapper that intercepts `@playwright/mcp@latest` so it sits ahead of `~/dot-files/node_modules/.bin/npx` in PATH).
- `read` on `~/dot-files/node_modules` (prettier and other dev-tool binaries; `bashrc` puts `~/dot-files/node_modules/.bin` on PATH ahead of `/usr/bin`, so the dir must be readable or `npm`, `prettier`, etc. fail with `Permission denied` before they run). Paired with `NPM_CONFIG_CACHE=$PWD/.tmp/cache/npm` in `bin/nn` to keep npm's cache off the read-only `~/.npm` path.
- `read` on `~/.config/gh` (git push over HTTPS via gh credential helper).
- `read_file` on `/etc/gitconfig` (system-wide gitconfig outside the base `git_config` group's coverage).
- `read_file` on `~/dot-files/claude/CLAUDE.md` (the global Claude Code instructions). `~/.claude/CLAUDE.md` is a symlink to this path; without the grant the harness can't follow the symlink and none of the global instructions load in sandboxed sessions. Single-file grant rather than a `read` on `~/dot-files/claude/` — `statusline-command.sh` is the only other file under there the sandbox needs, and it's already granted below.
- `read_file` on `~/dot-files/claude/statusline-command.sh` (the Claude Code statusline script, run sandboxed as a child of claude; `bin/nn` injects the matching `statusLine` block into the session settings since the sandbox can't read `~/.claude/settings.json`).
- `bypass_protection` on `~/.bashrc` → `~/dot-files/bashrc` (so `nono shell` and rc-loading don't trip the `deny_shell_configs` overlap; safe since this repo is public and scanned for secrets).

See `claude-nono/Makefile` in this repo for the maximalist reference set.
