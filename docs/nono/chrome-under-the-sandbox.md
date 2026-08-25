# Full Chrome and Playwright under the nono sandbox

Background for `oalders-chrome.json` and the browser handling in `bin/nn`. The
`superpowers-chrome` MCP (`nn --chrome`) drives the **full** Google Chrome
build, not Playwright's headless shell. Two things break it under the sandbox;
`bin/nn` and `oalders-chrome.json` fix both, gated on `--chrome` (#970).

## 1. Crashpad crash database

Full Chrome writes its crash database to
**`~/.config/google-chrome/Crash Reports`** — a fixed path derived from the
default config dir, *independent of `--user-data-dir`*. The base `claude-code`
profile denies that tree via `deny_browser_data_linux`. When Chrome can't write
there it launches its crashpad handler without a `--database` argument; the
handler aborts (`--database is required`) and the browser **SIGTRAPs on
startup** (exit 133). The Playwright headless shell is immune (no separate
crashpad handler).

The fix is narrow:

- `oalders-chrome.json` grants **only** the `Crash Reports` subdir
  (`filesystem.allow`) and lifts the deny on it (`filesystem.bypass_protection`).
  nono rejects a `bypass_protection` path with no matching grant, so the two must
  name the **same** path. Keeping the grant on the subdir leaves the sibling
  `Default/` (cookies, passwords, sessions) denied — the whole point of
  `deny_browser_data_linux`.
- A grant can't *create* the dir (its parent stays denied), so `bin/nn`
  pre-creates it outside the sandbox before launch (same pattern as
  `.tmp`/`.serena-home`).

The crashpad-disabling flags the issue floated (`--disable-crashpad`,
`--no-crashpad`, `--disable-crash-reporter`, `--disable-features=Crashpad`) do
**not** prevent the handler from spawning on this Chrome build — confirmed by
experiment.

## The Playwright MCP hits the same crash, fixed differently

`@playwright/mcp` defaults to the `chrome` channel — system Google Chrome — which
SIGTRAPs on the crashpad database exactly as above (`nn --playwright` → `browser
crashed on launch (SIGTRAP)`). The Playwright MCP is *not* granted the
`Crash Reports` dir (that's `--chrome`-only), so the fix is to point it away from
system Chrome: the `installer/playwright-mcp.sh`-generated `~/dot-files/bin/npx`
wrapper execs `playwright-mcp --browser chromium --headless`, driving
Playwright's bundled Chrome for Testing from the shared `~/.cache/ms-playwright`
bundle. That build hits the identical denied crash-reports dir
(`~/.config/google-chrome-for-testing/Crash Reports`) but only **logs a
non-fatal** permission error and keeps running — so no grant is needed, just the
switch off system Chrome. (`--headless` because the sandbox has no display.)

## 2. `Socket path too long` in deep worktrees

Once it launches, Chromium's process-singleton opens a Unix domain socket at
`<user-data-dir>/SingletonSocket`, and Playwright creates that user-data-dir
under `$TMPDIR`. `bin/nn` sets `TMPDIR=$PWD/.tmp` (to keep scratch inside
`--allow-cwd`), so in a dated worktree like `~/.worktree/<repo>/<date>/<name>`
the prefix plus `org.chromium.Chromium.XXXXXX/SingletonSocket` overruns the
~108-char `sun_path` limit and Chromium FATALs (`Socket path too long`). The same
`bin/npx` wrapper redirects **just the browser's** `TMPDIR` to the short,
already-granted `/tmp/claude-<uid>` scratch base (`oalders-core`
`filesystem.allow`); the session-wide `TMPDIR` and every other tool's scratch
stay in `$PWD/.tmp`. Guarded by `mkdir -p`, so a context where that base isn't
writable falls back to the inherited `TMPDIR`.

## Localhost ports `bin/nn` opens

Every localhost port `bin/nn` grants, and its trigger. All non-default grants use
repeated `nono run --open-port` (localhost connect + listen), scoped so idle
sandboxes keep them closed.

| Port(s) | Opened when | For |
| --- | --- | --- |
| `80`, `5000`, `5001`, `8080` | always (default chain) | `oalders-net`'s baseline `open_port` |
| `9222` | `--chrome` | Chrome DevTools endpoint the superpowers-chrome MCP drives |
| `9323`–`9342` | `playwright_enabled` (e2e markers or `--playwright`) | Playwright HTML report / trace viewer (`9323`) + preview / `webServer` (`9324`–`9342`) |
| `1313`–`1316` | Hugo detected **and** host has a tailscale IPv4 | `hugo server` reachable over the tailnet |

### DevTools TCP port (9222)

The superpowers-chrome MCP serves the Chrome DevTools endpoint over a localhost
TCP port (default range 9222–12111), but the default chain only opens
`[80, 5000, 5001, 8080]`, so `bind()` fails (`Cannot start http server for
devtools`). `bin/nn` pins the MCP to one fixed port via `CHROME_WS_PORT=9222` and
opens exactly that port. Done via the CLI flag rather than a `*-net` sibling
because nono's `extends` resolves by **name only**, so a net sibling can't
compose onto the path-based profiles `nn` builds. Scoped to `--chrome`. (The
Playwright MCP sidesteps this by talking to the browser over a stdio pipe, not a
TCP port — which is also why the headless shell "just works".)

### Playwright test ports (9323–9342)

The Playwright MCP needs no port, but running actual Playwright **tests** does:
the HTML report / trace viewer (preferredPort `9323`, increments when busy) and
any local preview / `config.webServer`. `bin/nn` opens a 20-port block
`9323–9342`; `9323` is Playwright's own default so the reporter works untouched,
and `9324–9342` are free for a preview/`webServer` — **serve within this range**
(e.g. `python -m http.server 9324 --bind 127.0.0.1`), since a bind outside it is
still denied. Scoped to `playwright_enabled`.

### Hugo serve ports over Tailscale (1313–1316)

To preview a Hugo build from another tailnet device, `hugo server` must bind the
host's **tailscale IPv4** rather than loopback:
`hugo server --bind $TAILSCALE_IP --baseURL http://$TAILSCALE_IP:1313/`. nono's
network mediation is port-based, so serving on that IP just needs the port
opened; the default chain doesn't cover Hugo's default `1313`. When Hugo is
detected **and** the host has a tailscale IPv4, `bin/nn`:

- opens the `1313–1316` block (room for a second instance or a custom `--port`);
- exports `TAILSCALE_IP` so the command above is copy-pasteable;
- appends the tailscale IP to `NO_PROXY`, so an in-sandbox client reaches the
  served site directly instead of routing through the credential proxy (which has
  no `allow_domain` entry for it and would block the connection).

The IPv4 comes from `tailscale ip -4`, falling back to the `tailscale0` interface
via `ip addr`. Gated on a tailscale IP existing, so non-tailnet Hugo sandboxes
keep the ports closed. Detection lives near the top of `bin/nn` (not only in the
mixin auto-gen block) so the grant still fires when a pre-generated
`.nono/profile.json` or a `--profile` override skips that block.
