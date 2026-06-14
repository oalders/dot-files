# nono permissive Perl-testing profile design

## Purpose

CPAN module test suites often need capabilities the default `oalders` nono
profile denies: calling out to arbitrary internet hosts, and binding to a
localhost port (frequently a random/ephemeral one, e.g. `Test::TCP`). Provide
an **opt-in** profile, `oalders-perl-test`, that grants open outbound network
and unrestricted localhost binding for these sessions, while keeping the same
filesystem lockdown as every other session.

## Background: why this needs a reorganization, not a mixin

nono's profile `extends` is **append-only** for array fields including
`allow_domain`, `open_port`, and `listen_port`. There is no mechanism to
*remove* an inherited entry. Two consequences, both verified:

1. **Any `allow_domain` entry anywhere in the inheritance chain flips nono into
   proxy allowlist mode** (default-deny outbound; only listed domains pass).
   Confirmed by lived experience: `oalders` sets `allow_domain`, and arbitrary
   internet is blocked under it.
2. **`open_port`/`listen_port` are allowlists; with *no* port rules in the
   chain, localhost binding is unrestricted.** Verified 2026-06-13:

   ```
   cd "$TMPDIR" && nono run --allow-cwd --read ~/.plenv -- perl -MIO::Socket::INET \
     -e 'my $s=IO::Socket::INET->new(Listen=>5,LocalAddr=>"127.0.0.1",LocalPort=>0) or die;
         my $p=$s->sockport;
         IO::Socket::INET->new(PeerAddr=>"127.0.0.1",PeerPort=>$p) or die;
         print "OK $p\n"'
   # => net outbound allowed; "OK bound+connected 46745"
   ```

Therefore a profile that wants open network and open ports **cannot** be a mixin
layered on top of `oalders` — it would inherit `oalders`'s `allow_domain` and
`open_port` and be stuck with them. The restrictions must be lifted *out* of the
shared base so a permissive profile can compose the grants without them.

A second finding shaped the design: `oalders-uv` itself sets
`allow_domain: [pypi.org, files.pythonhosted.org]`. Because `oalders` always
extends `oalders-uv`, that sibling also forces allowlist mode. So it is not
enough to de-restrict `oalders`; **every** grant sibling pulled into the shared
base must be net-free, with all domains/ports consolidated into dedicated `*-net`
siblings.

## Core principle

> Every grant sibling (filesystem/runtime) is **net-free**. *All* `allow_domain`,
> `open_port`, and `listen_port` live in dedicated `*-net` siblings. Restrictions
> are **composed on top** of a net-free base, never inherited from it.

This extends the repository's existing "composable single-purpose siblings"
model along the one axis that matters for nono: restrictions vs. grants.

## Architecture

### New / changed profiles

| File | Change | Holds |
|------|--------|-------|
| `oalders-core.json` | **new** | `extends: [claude-code, oalders-uv, oalders-serena, oalders-playwright, oalders-chrome]`, `security` block, cross-cutting `filesystem` block. **No `network`.** The net-free shared base. |
| `oalders-net.json` | **new** | `network_profile: null` + the curated `allow_domain` list + `open_port` from today's `oalders`, **plus** `pypi.org`/`files.pythonhosted.org` moved out of `oalders-uv`. The `network_profile: null` must ride along: it is the documented defensive opt-out (see `nono/CLAUDE.md`, "Why `network_profile` is set to `null`") and must not be dropped in the move. |
| `oalders-uv.json` | **changed** | Drop its `network` block → fs-only (`~/.local/share/uv`). |
| `oalders.json` | **changed** | Becomes `{"extends": ["oalders-core", "oalders-net"]}`. |
| `oalders-perl.json` | **changed** | Drop its `network` block → fs-only. |
| `oalders-perl-net.json` | **new** | The CPAN/MagPie `allow_domain` list moved out of `oalders-perl`. |
| `oalders-perl-test.json` | **new (opt-in)** | `extends: [oalders-core, oalders-perl]`. No `network` block ⇒ open outbound + unrestricted localhost ports, with full MCP runtimes, perl fs grants, and the same fs lockdown. |

Each new profile carries a `meta.name`/`meta.description` block, matching the
convention of the existing siblings (`oalders.json` itself has none today; the
new files follow the sibling convention, not `oalders`'s).

### Non-profile changes

| File | Change |
|------|--------|
| `bin/nn` | Perl detection appends **both** `oalders-perl` and `oalders-perl-net` to `mixins` (was just `oalders-perl`). **Regression risk:** appending only `oalders-perl` (the fs half) would silently strip all CPAN network access from every auto-detected Perl session. Both entries must land together; this is the single highest-risk edit. |
| `installer/symlinks.sh` | Symlink exactly the four new profiles into `~/.config/nono/profiles/`: `oalders-core.json`, `oalders-net.json`, `oalders-perl-net.json`, `oalders-perl-test.json`. (`oalders.json`/`oalders-perl.json`/`oalders-uv.json` already have symlinks and only change content.) |
| `nono/CLAUDE.md` | Document the core/net split, the core principle, and the opt-in permissive profile. Also fix now-stale rows in the existing tables: the `oalders-uv` row (no longer owns network) and the `oalders-perl` row (network moves to `oalders-perl-net`). |

## Behavior preservation (the critical invariant)

Every existing session must behave **identically** after this change. The
refactor only relocates blocks; it adds no grants and removes none from the
default path.

- `oalders` = `[oalders-core, oalders-net]`. `oalders-core` supplies what was
  `oalders`'s `extends` + `security` + `filesystem`; `oalders-net` supplies what
  was `oalders`'s `network`, plus uv's two domains (which previously arrived via
  `oalders-uv`). Net effect on the resolved capability set: zero change.
- Normal Perl sessions: `nn` now composes `oalders + oalders-perl +
  oalders-perl-net`. `oalders-perl` (fs) + `oalders-perl-net` (CPAN domains)
  together equal today's `oalders-perl`. Zero change.
- `oalders-uv` loses its domains but they reappear via `oalders-net` (always
  extended by `oalders`). `oalders-uv` is reached *only* through `oalders`
  (nothing else extends it), so every uv consumer still gets pypi via
  `oalders-net`. Zero change.
- `network_profile: null` moves from `oalders`'s inline `network` block into
  `oalders-net`, which `oalders` always extends — so it still resolves on
  `oalders`. Without it the move would silently drop the defensive opt-out.

## The permissive profile

`oalders-perl-test`:

- **Opt-in only.** Not auto-detected by `nn`; invoked explicitly with
  `nn --profile oalders-perl-test`. `nn`'s existing `--profile` override path
  resolves the name against `~/.config/nono/profiles/` and already adds
  `--read-file /usr/bin/env`.
- **Open network:** no `allow_domain` anywhere in its chain
  (`oalders-core` and `oalders-perl` are both net-free), so nono leaves outbound
  open.
- **Open localhost ports:** no `open_port`/`listen_port` in its chain, so binding
  to any loopback port (including ephemeral) is unrestricted.
- **Same filesystem lockdown:** it still extends `claude-code` (via
  `oalders-core`), so `deny_credentials`, `deny_keychains_*`, `deny_browser_*`,
  `deny_shell_history`, `deny_shell_configs`, etc. all still apply. Only network
  and loopback ports open up — the dangerous filesystem surface stays denied.

## Error handling / failure modes

- **MCP servers (serena/uv):** `oalders-perl-test` includes `oalders-core`, which
  carries the uv runtime fs grant and the serena/playwright/chrome grants, so
  MCP servers launch the same as in a normal session. `nn`'s per-launch serena
  setup (`SERENA_HOME=$PWD/.serena-home` + seed `serena_config.yml`) runs for
  *every* invocation including `nn --profile oalders-perl-test`, so serena is
  configured identically. The fact that uv's pypi domains are not in this chain
  is **not** a problem here: `oalders-perl-test` has *open* outbound (no
  allowlist), so `uvx` can reach pypi like any host if it needs to revalidate or
  fetch. (pypi being in `oalders-net` only matters for the locked `oalders` path,
  where allowlist mode is in effect.)
- **Validation:** each new/changed profile must pass
  `nono policy validate ~/.config/nono/profiles/<file>.json`.

## Testing / verification

1. **Behavior-preservation smoke test** (run from `$TMPDIR`, per `nono/CLAUDE.md`):
   `cd "$TMPDIR" && nono run --profile oalders --allow-cwd -- true` succeeds with
   no new denials.
2. **Permissive network:** under `oalders-perl-test`, an outbound request to a
   host *not* in any allowlist (e.g. `example.com`) succeeds.
3. **Permissive ports:** under `oalders-perl-test`, the bind+connect one-liner
   above succeeds (it already passes with no port rules; confirm the profile
   chain introduces none).
4. **Default still locked:** under `oalders` (or an auto-detected perl wrapper),
   the same off-allowlist outbound request still fails, and binding an
   off-list port still fails — proving the reorg did not loosen the default.

## Out of scope

- No `nn` convenience flag (e.g. `--perl-test`); `nn --profile oalders-perl-test`
  is sufficient.
- No splitting of `oalders-node` / `oalders-go` / `oalders-hugo` along the
  fs/net axis. Only `oalders-uv` and `oalders-perl` are split, because they are
  the siblings the permissive Perl profile must reuse net-free. Other siblings
  can adopt the pattern later if a permissive variant is ever needed.
- No permissive variants for other stacks. This design delivers Perl only.
