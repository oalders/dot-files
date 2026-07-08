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
| `oalders-playwright`| `~/.cache/ms-playwright` (host Chromium bundle, **read-only**), `/dev/shm` (browser IPC). `bin/nn` sets `PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright` so every worktree (and the in-sandbox MCP) shares the one host bundle instead of re-downloading ~265 MB into each worktree's `XDG_CACHE_HOME` (#975). The bundle is **read-only** to the sandbox: a session executes browser binaries but can never write them, so there is nothing to poison — not for a later host/un-sandboxed `playwright` run, and not for another sandboxed session sharing the bundle. Seeded and kept current on the host by `installer/playwright-mcp.sh` (`playwright install`); keep the host Playwright in step with the versions projects pin (this is a single-user dev box, so that's a deliberate, accepted maintenance task rather than something to engineer around). An in-sandbox `playwright install` for a not-yet-seeded build fails loudly against the read-only path — the cue to refresh the bundle on the host. Net-free; the browser-download CDN hosts live in the paired `oalders-playwright-net` (composed into `oalders.json`'s `extends`, not `oalders-core`'s, so only the default chain gets them). |
| `oalders-chrome`    | `/opt/google/chrome` (browser binary), `~/.cache/superpowers` (browser session dirs), `~/.config/google-chrome/Crash Reports` (crashpad database — grant + `bypass_protection`; see "superpowers-chrome (full Chrome) under the sandbox") |

### Project-detected (mixed in by `nn`)

`nn` scans the repo top when no `.nono/profile.json` exists yet, and writes a wrapper composing `oalders` with any matching sibling.

| Profile         | Markers at repo root                  | Owns                                                                               |
| --------------- | ------------------------------------- | ---------------------------------------------------------------------------------- |
| `oalders-perl`  | `cpanfile`, `Makefile.PL`, `dist.ini` | plenv (`~/.plenv`), local::lib (`~/perl5`), Dist::Zilla (`~/.dzil`, `~/dot-files/dzil`), prove (`~/.proverc`), XS system C headers (`/usr/include`, `/usr/local/include`). Net-free; CPAN/MetaCPAN/MagPie network is in the paired `oalders-perl-net` (appended alongside it by `nn`). |
| `oalders-node`  | `package.json`                        | `*.npmjs.org`, `registry.npmjs.org` (npm registry network access for installs)     |
| `oalders-go`    | `go.mod`                              | Go toolchain (`go_runtime` group), build/module/lint caches (`~/.cache/go-build`, `~/.cache/golangci-lint`, `~/go/pkg/mod`), module proxy + checksum DB (`proxy.golang.org`, `sum.golang.org`), and cgo system headers (`/usr/include`, `/usr/local/include`, `/opt/homebrew/include`, pkg-config dirs, `/Library/Developer/CommandLineTools`) |
| `oalders-hugo`  | `hugo.toml` / `hugo.yaml` / `hugo.json`, or `config.toml` + `themes/` | Hugo cache (`~/.cache/hugo_cache`). When Hugo matches, `nn` also appends `oalders-snap` to the mixin list because Hugo on Linux is typically snap-installed, and — if the host is on a tailnet — opens Hugo's serve ports over the tailscale IP (see §2c). |
| `oalders-snap`  | (no markers of its own — `nn` appends it alongside any snap-backed sibling like `oalders-hugo`) | Reads for snap-confined binaries: `/snap`, `/var/lib/snapd`, `/etc/fstab` (snapd's startup checks parse the mount table). |

Example wrapper for a Node + Perl repo (`package.json` + `cpanfile` at top):

```json
{"extends": ["oalders", "oalders-perl", "oalders-node"]}
```

### Opt-in only (no auto-detection)

These siblings are symlinked into `~/.config/nono/profiles/` but aren't mixed in by `oalders.json` or `bin/nn` — a repo that wants them lists them in its own `.nono/profile.json`. Use when the tool's marker would produce too many false positives (e.g. `*.tf` files can show up in non-IaC repos as fixtures), or the use case is rare enough that auto-detect overhead isn't worth it.

| Profile             | Owns                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------- |
| `oalders-ansible`   | `~/.local/share/pipx/venvs/ansible` (read; the pipx venv whose binaries `~/.local/bin/ansible*` symlink into — the read grant is what lets them run). Filesystem only, no network — SSH egress to deploy targets stays out of scope. Opt-in because ansible is deploy-host tooling rarely used inside dev repos. |
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
- `filesystem.read_file: ["/etc/gitconfig"]`. The base `git_config` group covers `~/.gitconfig` and `~/.config/git/ignore` but not the system-wide gitconfig. Without it, every `git` invocation fails with `fatal: unknown error occurred while reading the configuration files`.
- `filesystem.read: ["~/.config/gh"]`. Needed for `git push` over HTTPS when gh is the credential helper — gh reads `config.yml` and `hosts.yml` (OAuth token) to answer git's username/password prompt. Read-only is enough for pushes; bump to `allow` if a workflow needs gh to update its own state.
- `nn` passes `--allow $(git rev-parse --git-common-dir)` when cwd is a git worktree. The worktree's `.git` lives under the main repo (`<main>/.git/worktrees/<name>`), outside cwd — so `--allow-cwd` alone leaves git unable to read objects/refs.
- `SERENA_HOME=$PWD/.serena-home` set inside `nn` before claude launches. Serena's `SerenaConfig.from_config_file()` reads every entry in `~/.serena/serena_config.yml`'s `registered_projects` on startup; if any path is outside the sandbox the MCP server crashes with `Permission denied` before the requested project is even activated. Pointing `SERENA_HOME` at a worktree-local dir (covered by `--allow-cwd`) gives each session a fresh, empty registry. Trade-off: serena's memories/logs no longer persist across worktrees — acceptable since the registry pollution was the actual problem and per-worktree scoping is desirable anyway.
- `nono/serena_config.yml` is the seed config that `nn` copies into `$PWD/.serena-home/serena_config.yml` on every launch. It sets `web_dashboard: false` (Landlock blocks the dashboard's port-bind walk from 24282 upward, crashing serena with `No free ports found starting from 24282`) and `projects: []` (re-enforced each launch so the per-worktree registry can never accumulate stale entries). Single source of truth for both settings; everything else falls back to serena defaults. Once this is in place, the `~/.serena` grant in `oalders-serena.json` is dead weight for sandboxed sessions — left in for now since non-sandboxed tooling may still touch it.

## Why `network_profile` is set to `null`

The `claude-code` network bundle (`network.network_profile`) sets up nono's reverse proxy and injects `ANTHROPIC_BASE_URL=http://127.0.0.1:<port>/anthropic`. The `anthropic` route demands `env://ANTHROPIC_API_KEY`; Max/OAuth users have no API key, so the proxy returns `407 Proxy Authentication Required` with body `{"error":"Proxy Authentication Required"}`. The startup `WARN ... requests will proceed without credential injection` is misleading — actual behavior is hard-reject.

Surfaced 2026-04-30 after claude auto-updated to a version that respects `ANTHROPIC_BASE_URL`. Earlier claude went to `api.anthropic.com` directly and tunneled through `HTTPS_PROXY`, dodging the intercept.

Workaround: set `"network_profile": null` in `oalders-net.json` (where all outbound rules now live) and replace the curated bundle with an explicit `allow_domain` list (Anthropic, GitHub, npm, Go module proxy). The explicit `null` is the documented opt-out pattern — see nono's `docs/cli/clients/claude-code.mdx` (`claude-code-netopen` example). Today the parent `claude-code` profile doesn't set `network_profile`, so omitting the field would also work, but `null` is defensive against a future nono release adding it back.

Upstream to watch:
- https://github.com/always-further/nono/issues/793 — exec-sourced credentials (covers `apiKeyHelper` shape)
- https://github.com/always-further/nono/issues/770 — refreshable credential backend
- https://github.com/always-further/nono/issues/724 — 3rd-party provider profiles

Re-test on each nono release: temporarily flip `"network_profile": null` to `"claude-code"` in `oalders-net.json` and run from `$TMPDIR`:
```
cd "${TMPDIR:-/tmp}" && nono run --profile oalders --allow-cwd -- curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST "$ANTHROPIC_BASE_URL/v1/messages" -d '{}'
```
Non-407 means the route became OAuth-aware and you can re-adopt the curated bundle. While `network_profile` is null, the `NO_PROXY` reset in `bin/nn` is vestigial (no proxy is started) but harmless — it re-becomes load-bearing the moment the curated bundle is restored.

## superpowers-chrome (full Chrome) under the sandbox

The `superpowers-chrome` MCP (opt-in via `nn --chrome`) drives the **full** Google Chrome build, not Playwright's headless shell. Two things break it under the sandbox; `bin/nn` and `oalders-chrome.json` fix both, gated on `--chrome` (#970).

### 1. Crashpad crash database

Full Chrome writes its crash database to **`~/.config/google-chrome/Crash Reports`** — a fixed path derived from the default config dir, *independent of `--user-data-dir`* (so pointing the session dir at `~/.cache/superpowers` doesn't move it). The base `claude-code` profile denies that tree via the `deny_browser_data_linux` group. When Chrome can't write there it launches its crashpad handler without a `--database` argument; the handler aborts with `chrome_crashpad_handler: --database is required` (plus `recvmsg: Connection reset by peer`), and the browser **SIGTRAPs on startup** (exit 133). The Playwright headless shell is immune because it ships no separate crashpad handler.

The fix is narrow:

- `oalders-chrome.json` grants **only** the `Crash Reports` subdir (`filesystem.allow`) and lifts the deny on it (`filesystem.bypass_protection`). nono rejects a `bypass_protection` path that has no matching grant, so the two must name the **same** path — you can't bypass the parent `~/.config/google-chrome` and allow only the child. Keeping the grant on the subdir leaves the sibling `Default/` (cookies, saved passwords, sessions) denied, which is the whole point of `deny_browser_data_linux`.
- A grant can't *create* the dir (its parent stays denied), so `bin/nn` pre-creates `~/.config/google-chrome/Crash Reports` outside the sandbox before launch (same pattern as `.tmp`/`.serena-home`). Without the dir, Chrome can't establish the database and the crash returns.

The crashpad-disabling flags the issue floated (`--disable-crashpad`, `--no-crashpad`, `--disable-crash-reporter`, `--disable-features=Crashpad`) do **not** prevent the handler from spawning on this Chrome build — confirmed by experiment — so disabling crashpad is not a viable alternative to the grant.

**The Playwright MCP hits the *same* crash by default, and is fixed differently.** `@playwright/mcp` defaults to the `chrome` channel — system Google Chrome at `/opt/google/chrome/chrome` — which SIGTRAPs on the crashpad database exactly as above (symptom: `nn --playwright` → `browser crashed on launch (SIGTRAP)` before any page loads, and running `/opt/google/chrome/chrome --headless --no-sandbox` directly reproduces exit 133). The Playwright MCP is *not* granted the `Crash Reports` dir (that's `--chrome`-only), so the fix is to point it away from system Chrome entirely: the `installer/playwright-mcp.sh`-generated `~/dot-files/bin/npx` wrapper execs `playwright-mcp --browser chromium --headless`, driving Playwright's own bundled Chrome for Testing from the shared `~/.cache/ms-playwright` bundle. That build hits the identical denied crash-reports dir (`~/.config/google-chrome-for-testing/Crash Reports`) but only logs a **non-fatal** permission error and keeps running — so no grant is needed, just the switch off system Chrome. (`--headless` because the sandbox has no display; the empirically-observed launch is the full `chrome-linux64/chrome` binary in headless mode, not the separate `chrome-headless-shell`.)

**And once it launches, a deep worktree trips a second failure: `Socket path too long`.** Chromium's process-singleton opens a Unix domain socket at `<user-data-dir>/SingletonSocket`, and Playwright creates that user-data-dir under `$TMPDIR`. `bin/nn` sets `TMPDIR=$PWD/.tmp` (to keep scratch inside `--allow-cwd`), so in a dated worktree like `~/.worktree/<repo>/<date>/<name>` the prefix plus `org.chromium.Chromium.XXXXXX/SingletonSocket` overruns the ~108-char `sun_path` limit and Chromium FATALs (`process_singleton_posix.cc: Socket path too long`) before any page loads. The same `bin/npx` wrapper redirects **just the browser's** `TMPDIR` to the short, already-granted `/tmp/claude-<uid>` scratch base (`oalders-core` `filesystem.allow`) so the socket fits; the session-wide `TMPDIR` and every other tool's scratch stay in `$PWD/.tmp`. The redirect is guarded by `mkdir -p`, so a context where that base isn't writable just falls back to the inherited `TMPDIR`.

### 2. DevTools TCP port

The MCP serves the Chrome DevTools endpoint over a localhost TCP port (its default range is 9222–12111), but the default chain only opens `[80, 5000, 5001, 8080]` (`oalders-net`'s `open_port`). The `bind()` fails with `Cannot start http server for devtools` and the MCP can't drive the browser. (The **Playwright MCP** sidesteps *this* by talking to the browser over a stdio pipe, not a TCP port — which is also why the headless shell "just works" — but see the Playwright note below: running actual Playwright *tests* still needs ports.)

`bin/nn` pins the MCP to one fixed port via `CHROME_WS_PORT=9222` and opens exactly that port with `nono run --open-port 9222` (localhost connect + listen). Done via the CLI flag rather than a dedicated `*-net` sibling because nono's `extends` resolves by **name only** (not path), so a net sibling can't compose onto the path-based profiles `nn` builds (`.nono/profile.json` wrappers, `--profile` overrides); the flag is conditional by construction and works for every profile shape. Scoped to `--chrome` so idle and non-browser sandboxes keep the port closed.

### 2b. Playwright test ports (9323–9342)

The Playwright MCP drives the browser over a pipe, so it needs no port — but running actual Playwright **tests** in the sandbox does. Two consumers bind localhost TCP the default chain doesn't cover, so `bind()` is Landlock-denied (`permission denied 127.0.0.1:<port>`): Playwright's HTML report / trace viewer (preferredPort `9323`, increments when busy) and any local preview / `config.webServer` that serves the build for the browser to load.

`bin/nn` opens a 20-port block `9323–9342` with repeated `nono run --open-port` (same CLI-flag rationale as the DevTools port above). `9323` is Playwright's own default so the reporter works untouched; `9324–9342` are free for a preview/`webServer` — **serve within this range** (e.g. `python -m http.server 9324 --bind 127.0.0.1`), since a bind outside it is still denied. Scoped to `playwright_enabled` (e2e markers present, or `--playwright`) so idle/non-e2e sandboxes keep the ports closed.

### 2c. Hugo serve ports over Tailscale (1313–1316)

`hugo server` binds a single interface. To preview a build from another tailnet device (phone, laptop), it must bind the host's **tailscale IPv4** rather than loopback: `hugo server --bind $TAILSCALE_IP --baseURL http://$TAILSCALE_IP:1313/`. nono's network mediation is port-based, so serving on that IP just needs the serve port opened; the default chain's `open_port [80, 5000, 5001, 8080]` doesn't cover Hugo's default `1313`.

When Hugo is detected (same markers as the `oalders-hugo` mixin: `hugo.toml`/`yaml`/`json`, `config/_default/`, or `config.toml` + `themes/`) **and** the host has a tailscale IPv4, `bin/nn`:

- opens the `1313–1316` block with repeated `nono run --open-port` (same CLI-flag rationale as the ports above) — the small range leaves room for a second instance or a custom `--port` near the default;
- exports `TAILSCALE_IP` so the `--bind`/`--baseURL` command above is copy-pasteable and scripts can reference it;
- appends the tailscale IP to `NO_PROXY`, so an **in-sandbox** client (curl, the Playwright MCP) reaches the served site directly instead of routing through the credential proxy — which has no `allow_domain` entry for it and would block the connection.

The IPv4 comes from `tailscale ip -4` (cross-platform), falling back to the Linux `tailscale0` interface via `ip addr`. Gated on a tailscale IP actually existing, so non-tailnet Hugo sandboxes keep the ports closed and `NO_PROXY` at loopback. Detection lives near the top of `bin/nn` (not only in the mixin auto-gen block) so the grant still fires when a pre-generated `.nono/profile.json` or a `--profile` override skips that block — the serve grant follows the project, not the profile shape.

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
