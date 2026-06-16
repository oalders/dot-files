# nono permissive Perl-testing profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the nono profiles so all network rules live in dedicated `*-net` siblings, then add an opt-in `oalders-perl-test` profile that grants open outbound network and unrestricted localhost ports for CPAN test suites while keeping the same filesystem lockdown.

**Architecture:** nono's `extends` is append-only and any `allow_domain` in the chain forces proxy allowlist mode, so a permissive profile cannot remove inherited restrictions — restrictions must be lifted *out* of the shared base. Every grant sibling (filesystem/runtime) becomes net-free; all domains/ports move into `*-net` siblings; `oalders` recomposes them as `[oalders-core, oalders-net]`; `oalders-perl-test` composes only net-free grants (`[oalders-core, oalders-perl]`) so its chain has zero `allow_domain`/`open_port` ⇒ open network + open loopback ports.

**Tech Stack:** nono (Landlock sandbox) JSON profiles, Bash (`bin/nn` launcher, `installer/symlinks.sh`), bats tests.

**Reference spec:** `docs/superpowers/specs/2026-06-13-nono-perl-test-profile-design.md`

**Critical invariant:** every *existing* session must behave identically after this change. The reorg only relocates blocks — it adds and removes nothing from the default path. Each task below verifies this incrementally.

**Ordering trap (read before starting):** `bin/test-nono-claude-md.sh` and any local-file `nono why`/`nono run` against `nono/oalders.json` resolve the *named* `extends` (`oalders-core`, `oalders-net`) through `~/.config/nono/profiles/`. After Task 3 flips `oalders.json` to extend the new siblings, those siblings **must already be symlinked** or resolution fails. Each task that creates a profile also symlinks it live, before any verification depends on it.

---

## Task 1: Create the net-free shared base `oalders-core`

**Files:**
- Create: `nono/oalders-core.json`
- Test: live `nono policy validate`

This holds today's `oalders` `extends` + `security` + cross-cutting `filesystem`, with **no** `network` block. Creating it changes nothing yet (nothing extends it).

- [ ] **Step 1: Create the profile file**

Create `nono/oalders-core.json` with exactly:

```json
{
  "meta": {
    "name": "oalders-core",
    "description": "Net-free shared base: always-on MCP/runtime siblings, security policy, and cross-cutting filesystem grants. Holds no network rules so permissive profiles can compose it without inheriting an allowlist."
  },
  "extends": [
    "claude-code",
    "oalders-uv",
    "oalders-serena",
    "oalders-playwright",
    "oalders-chrome"
  ],
  "security": {
    "signal_mode": "allow_same_sandbox",
    "process_info_mode": "allow_same_sandbox",
    "ipc_mode": "full"
  },
  "filesystem": {
    "read": [
      "/usr/libexec/gcc",
      "/usr/local/",
      "~/.config/gh",
      "~/.local/bin",
      "~/.local/share/nvim/mason",
      "~/.npm-packages",
      "~/dot-files/bin",
      "~/dot-files/gitignore_global",
      "~/dot-files/node_modules",
      "~/dot-files/nono",
      "~/local/bin"
    ],
    "allow": [
      "/tmp/claude-1000"
    ],
    "read_file": [
      "/etc/bash.bashrc",
      "/etc/gitconfig",
      "~/.bashrc",
      "~/.docker/config.json",
      "~/.gitconfig",
      "~/dot-files/bashrc",
      "~/dot-files/claude/CLAUDE.md",
      "~/dot-files/claude/statusline-command.sh"
    ],
    "allow_file": [
      "~/.claude/.credentials.json"
    ],
    "bypass_protection": [
      "~/.bashrc",
      "~/dot-files/bashrc"
    ]
  }
}
```

- [ ] **Step 2: Symlink it live so named-extends resolution can find it**

Run:
```bash
ln -sf ~/dot-files/nono/oalders-core.json ~/.config/nono/profiles/oalders-core.json
```
Expected: no output, exit 0.

- [ ] **Step 3: Validate the profile resolves**

Run: `nono policy validate ~/.config/nono/profiles/oalders-core.json`
Expected: validates OK (no errors). It resolves `claude-code` + the four always-on siblings, all already symlinked.

- [ ] **Step 4: Commit**

```bash
git add nono/oalders-core.json
git commit -m "Add net-free oalders-core base profile"
```

---

## Task 2: Create the network sibling `oalders-net`

**Files:**
- Create: `nono/oalders-net.json`
- Test: live `nono policy validate`

This holds today's `oalders` `network` block (including `network_profile: null`) **plus** uv's two PyPI domains, so `oalders-uv` can go net-free in Task 4. Creating it changes nothing yet (nothing extends it).

- [ ] **Step 1: Create the profile file**

Create `nono/oalders-net.json` with exactly:

```json
{
  "meta": {
    "name": "oalders-net",
    "description": "All outbound network rules for the default oalders chain: curated allow_domain list, open_port, and the defensive network_profile:null opt-out. Includes uv's PyPI domains so the uv sibling can stay net-free."
  },
  "network": {
    "network_profile": null,
    "allow_domain": [
      "*.anthropic.com",
      "*.claude.ai",
      "*.github.com",
      "*.githubusercontent.com",
      "api.anthropic.com",
      "claude.ai",
      "datatracker.ietf.org",
      "files.pythonhosted.org",
      "github.com",
      "pypi.org",
      "www.rfc-editor.org"
    ],
    "open_port": [80, 5000, 5001, 8080]
  }
}
```

- [ ] **Step 2: Symlink it live**

Run:
```bash
ln -sf ~/dot-files/nono/oalders-net.json ~/.config/nono/profiles/oalders-net.json
```
Expected: no output, exit 0.

- [ ] **Step 3: Validate the profile**

Run: `nono policy validate ~/.config/nono/profiles/oalders-net.json`
Expected: validates OK.

- [ ] **Step 4: Commit**

```bash
git add nono/oalders-net.json
git commit -m "Add oalders-net profile carrying all outbound network rules"
```

---

## Task 3: Recompose `oalders.json` from the new siblings

**Files:**
- Modify: `nono/oalders.json` (replace entire contents)
- Test: `bin/test-nono-claude-md.sh`, behavior-preservation smoke test

After this, `oalders` = `[oalders-core, oalders-net]`. `oalders-core` supplies the old `extends` + `security` + `filesystem`; `oalders-net` supplies the old `network` + uv's domains. At this point `oalders-uv` still carries its own domains too — harmless duplication (append-only dedups), removed in Task 4. Net resolved capability set: unchanged.

- [ ] **Step 1: Replace `nono/oalders.json` with the composition root**

Replace the entire contents of `nono/oalders.json` with exactly:

```json
{
  "extends": [
    "oalders-core",
    "oalders-net"
  ]
}
```

- [ ] **Step 2: Verify the CLAUDE.md read grant still resolves (regression test for issue #948)**

Run: `bin/test-nono-claude-md.sh`
Expected: `ok: <repo>/nono/oalders.json grants read on <home>/.claude/CLAUDE.md`
(This passes only because `oalders-core` is already symlinked from Task 1 and carries the `~/dot-files/claude/CLAUDE.md` `read_file` grant.)

- [ ] **Step 3: Behavior-preservation smoke test**

Run:
```bash
cd "${TMPDIR:-/tmp}" && nono run --profile oalders --allow-cwd -- true; cd - >/dev/null
```
Expected: exit 0, no new denial warnings.

- [ ] **Step 4: Confirm the network allowlist still resolves on `oalders`**

Run: `nono why --host github.com --op connect --profile ~/.config/nono/profiles/oalders.json`
Expected: an `ALLOWED` line for `github.com` (proves the curated allowlist survived the move into `oalders-net`).

- [ ] **Step 5: Commit**

```bash
git add nono/oalders.json
git commit -m "Recompose oalders.json from oalders-core + oalders-net"
```

---

## Task 4: Make `oalders-uv` net-free

**Files:**
- Modify: `nono/oalders-uv.json` (drop the `network` block)
- Test: live `nono policy validate`, `nono why` for pypi

`oalders-uv` is reached only via `oalders` (nothing else extends it), so dropping its domains is safe: they reappear through `oalders-net`, which `oalders` always extends.

- [ ] **Step 1: Replace `nono/oalders-uv.json` with the fs-only version**

Replace the entire contents of `nono/oalders-uv.json` with exactly:

```json
{
  "meta": {
    "name": "oalders-uv",
    "description": "uv runtime filesystem: location used by uv-installed tools (uvx, uv tool install). Net-free; PyPI domains live in oalders-net."
  },
  "filesystem": {
    "read": [
      "~/.local/share/uv"
    ]
  }
}
```

- [ ] **Step 2: Validate the changed profile**

Run: `nono policy validate ~/.config/nono/profiles/oalders-uv.json`
Expected: validates OK.

- [ ] **Step 3: Confirm pypi is still reachable under `oalders` (now via oalders-net)**

Run: `nono why --host pypi.org --op connect --profile ~/.config/nono/profiles/oalders.json`
Expected: an `ALLOWED` line for `pypi.org` (proves the domain survived the move from `oalders-uv` into `oalders-net`).

- [ ] **Step 4: Commit**

```bash
git add nono/oalders-uv.json
git commit -m "Make oalders-uv net-free; PyPI domains now in oalders-net"
```

---

## Task 5: Split Perl into net-free `oalders-perl` + new `oalders-perl-net`, and update `bin/nn`

**Files:**
- Create: `nono/oalders-perl-net.json`
- Modify: `nono/oalders-perl.json` (drop the `network` block)
- Modify: `bin/nn:94` (append both perl mixins)
- Test: live `nono policy validate`, manual wrapper inspection

The highest-risk edit: `bin/nn` must append **both** `oalders-perl` (fs) and `oalders-perl-net` (CPAN domains). Appending only the fs half would silently strip CPAN network from every auto-detected Perl session.

- [ ] **Step 1: Create `nono/oalders-perl-net.json`**

Create `nono/oalders-perl-net.json` with exactly:

```json
{
  "meta": {
    "name": "oalders-perl-net",
    "description": "CPAN/MetaCPAN/MagPie network access for Perl sessions, split out of oalders-perl so the filesystem grants can be reused net-free."
  },
  "network": {
    "allow_domain": [
      "*.cpan.org",
      "*.cpantesters.org",
      "*.metacpan.org",
      "*.perl-magpie.org",
      "cpan.org",
      "cpanmetadb.plackperl.org",
      "cpantesters.org",
      "metacpan.org"
    ]
  }
}
```

- [ ] **Step 2: Symlink `oalders-perl-net` live**

Run:
```bash
ln -sf ~/dot-files/nono/oalders-perl-net.json ~/.config/nono/profiles/oalders-perl-net.json
```
Expected: no output, exit 0.

- [ ] **Step 3: Replace `nono/oalders-perl.json` with the fs-only version**

Replace the entire contents of `nono/oalders-perl.json` with exactly:

```json
{
  "meta": {
    "name": "oalders-perl",
    "description": "Perl development mixin (filesystem only): plenv, local::lib (~/perl5), Dist::Zilla, prove, perlimports, common rc files, system C headers for XS. Net-free; CPAN domains live in oalders-perl-net."
  },
  "filesystem": {
    "allow": [
      "~/.plenv/shims"
    ],
    "read": [
      "/usr/include",
      "/usr/local/include",
      "~/.dzil",
      "~/.perl-cpm",
      "~/.plenv",
      "~/.proverc",
      "~/dot-files/dzil",
      "~/perl5"
    ],
    "read_file": [
      "~/.config/perlimports/perlimports.toml",
      "~/.dataprinter",
      "~/.perlcriticrc",
      "~/.perltidyrc",
      "~/dot-files/.perltidyrc",
      "~/dot-files/dataprinter",
      "~/dot-files/perlcriticrc",
      "~/dot-files/perlimports/perlimports.toml"
    ]
  }
}
```

- [ ] **Step 4: Validate both Perl profiles**

Run:
```bash
nono policy validate ~/.config/nono/profiles/oalders-perl.json
nono policy validate ~/.config/nono/profiles/oalders-perl-net.json
```
Expected: both validate OK.

- [ ] **Step 5: Update `bin/nn` to append both Perl mixins**

In `bin/nn`, change the Perl detection line (currently `bin/nn:94`):

```bash
        mixins+=("oalders-perl")
```

to:

```bash
        mixins+=("oalders-perl" "oalders-perl-net")
```

- [ ] **Step 6: Manually confirm the generated wrapper contains both entries**

`bin/nn` writes `.nono/profile.json` and then execs `nono`. To inspect the wrapper without launching a real session, stub `nono` to a no-op on PATH and run `nn` from a throwaway Perl repo:

```bash
tmp=$(mktemp -d "${TMPDIR:-/tmp}/nntest.XXXXXX")
mkdir -p "$tmp/stubs"; printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/stubs/nono"; chmod +x "$tmp/stubs/nono"
echo "requires 'Moo';" > "$tmp/cpanfile"
( cd "$tmp" && PATH="$tmp/stubs:$PATH" GIT_CEILING_DIRECTORIES="$tmp" "$PWD/bin/nn" >/dev/null 2>&1 )
cat "$tmp/.nono/profile.json"
rm -rf "$tmp"
```
Expected: the printed JSON's `extends` array contains both `"oalders-perl"` and `"oalders-perl-net"` (e.g. `{"extends": ["oalders", "oalders-perl", "oalders-perl-net"]}`).

> Note: the load-bearing, repeatable verification for this change is the bats test added in Task 8, which drives `bin/nn` end-to-end with a stubbed `nono`. This manual step is just a sanity glance.

- [ ] **Step 7: Commit**

```bash
git add nono/oalders-perl.json nono/oalders-perl-net.json bin/nn
git commit -m "Split oalders-perl into net-free fs + oalders-perl-net; nn appends both"
```

---

## Task 6: Add the `oalders-perl-test` permissive profile

**Files:**
- Create: `nono/oalders-perl-test.json`
- Test: live `nono policy validate`, `nono why` for an off-allowlist host, port bind+connect one-liner

`oalders-perl-test` = `[oalders-core, oalders-perl]`. Both are now net-free (Tasks 1, 5), so its chain has zero `allow_domain` ⇒ open outbound, and zero `open_port`/`listen_port` ⇒ unrestricted localhost binding. It still extends `claude-code` (via `oalders-core`), so all filesystem denies stay in force.

- [ ] **Step 1: Create `nono/oalders-perl-test.json`**

Create `nono/oalders-perl-test.json` with exactly:

```json
{
  "meta": {
    "name": "oalders-perl-test",
    "description": "Opt-in permissive Perl test profile: open outbound network and unrestricted localhost ports for CPAN test suites (Test::TCP, live-network tests), with the same filesystem lockdown as oalders. Invoke via: nn --profile oalders-perl-test."
  },
  "extends": [
    "oalders-core",
    "oalders-perl"
  ]
}
```

- [ ] **Step 2: Symlink it live**

Run:
```bash
ln -sf ~/dot-files/nono/oalders-perl-test.json ~/.config/nono/profiles/oalders-perl-test.json
```
Expected: no output, exit 0.

- [ ] **Step 3: Validate the profile**

Run: `nono policy validate ~/.config/nono/profiles/oalders-perl-test.json`
Expected: validates OK.

- [ ] **Step 4: Verify open outbound — an off-allowlist host is permitted**

Run: `nono why --host example.com --op connect --profile ~/.config/nono/profiles/oalders-perl-test.json`
Expected: an `ALLOWED` line for `example.com` (no allowlist in the chain ⇒ outbound open). Contrast: the same query against `oalders` would be `DENIED`.

- [ ] **Step 5: Verify open localhost ports — bind + connect to an ephemeral port**

Run:
```bash
cd "${TMPDIR:-/tmp}" && nono run --profile oalders-perl-test --allow-cwd --read ~/.plenv -- \
  perl -MIO::Socket::INET -e 'my $s=IO::Socket::INET->new(Listen=>5,LocalAddr=>"127.0.0.1",LocalPort=>0) or die "listen: $!";
    my $p=$s->sockport;
    IO::Socket::INET->new(PeerAddr=>"127.0.0.1",PeerPort=>$p) or die "connect: $!";
    print "OK bound+connected $p\n"'; cd - >/dev/null
```
Expected: `OK bound+connected <some-random-port>` (the `--read ~/.plenv` is only so the plenv-shimmed `perl` is executable; it is not part of the profile).

- [ ] **Step 6: Confirm the default is still locked (the reorg did not loosen `oalders`)**

Run: `nono why --host example.com --op connect --profile ~/.config/nono/profiles/oalders.json`
Expected: a `DENIED` line for `example.com` (off-allowlist host still blocked under the default profile).

- [ ] **Step 7: Commit**

```bash
git add nono/oalders-perl-test.json
git commit -m "Add opt-in permissive oalders-perl-test profile"
```

---

## Task 7: Persist all four new symlinks in `installer/symlinks.sh`

**Files:**
- Modify: `installer/symlinks.sh` (add four `ln -sf` lines)
- Test: re-run the installer's symlink lines (idempotent), confirm targets

The live symlinks created in Tasks 1, 2, 5, 6 exist on this machine but won't survive a fresh install without these lines. The three *changed* files (`oalders.json`, `oalders-perl.json`, `oalders-uv.json`) already have symlink lines and need none added.

- [ ] **Step 1: Add the four new symlink lines**

In `installer/symlinks.sh`, find the block of `oalders-*.json` symlink lines (currently `installer/symlinks.sh:99-109`). Add these four lines into that block, keeping it readable:

Insert after the `oalders-chrome.json` line (`installer/symlinks.sh:99`):
```bash
ln -sf $prefix/nono/oalders-core.json ~/.config/nono/profiles/oalders-core.json
```

Insert after the `oalders-hugo.json` line:
```bash
ln -sf $prefix/nono/oalders-net.json ~/.config/nono/profiles/oalders-net.json
```

Insert after the `oalders-perl.json` line:
```bash
ln -sf $prefix/nono/oalders-perl-net.json ~/.config/nono/profiles/oalders-perl-net.json
ln -sf $prefix/nono/oalders-perl-test.json ~/.config/nono/profiles/oalders-perl-test.json
```

- [ ] **Step 2: Confirm the four symlinks point at the repo files**

Run:
```bash
for p in oalders-core oalders-net oalders-perl-net oalders-perl-test; do
  readlink ~/.config/nono/profiles/$p.json
done
```
Expected: four lines, each ending in `dot-files/nono/<name>.json`.

- [ ] **Step 3: Commit**

```bash
git add installer/symlinks.sh
git commit -m "Symlink the four new nono profiles in installer/symlinks.sh"
```

---

## Task 8: Regression-test the two-entry Perl append in `test/nn.bats`

**Files:**
- Modify: `test/nn.bats` (add one `@test`)
- Test: `bats test/nn.bats`

Locks in the highest-risk edit from Task 5 — that auto-detection appends **both** Perl mixins. The existing suite stubs `nono` and asserts the generated wrapper; this test follows the same pattern as the Hugo detection test.

- [ ] **Step 1: Add the regression test**

Append this `@test` to the end of `test/nn.bats`:

```bash
@test "bin/nn auto-detect appends both oalders-perl and oalders-perl-net" {
    # A cpanfile marks a Perl repo; detection must compose BOTH the fs mixin
    # (oalders-perl) and the network mixin (oalders-perl-net). Appending only
    # the fs half would silently strip CPAN network from auto-detected sessions.
    echo "requires 'Moo';" > cpanfile
    run "$NN"
    [ "$status" -eq 0 ]
    [ -f .nono/profile.json ]
    grep -Fq '"oalders-perl"' .nono/profile.json
    grep -Fq '"oalders-perl-net"' .nono/profile.json
}
```

- [ ] **Step 2: Run the new test and confirm it passes**

Run: `bats test/nn.bats -f "appends both oalders-perl"`
Expected: `1 test, 0 failures`.

- [ ] **Step 3: Run the full nn suite to confirm no regressions**

Run: `bats test/nn.bats`
Expected: all tests pass, 0 failures.

- [ ] **Step 4: Commit**

```bash
git add test/nn.bats
git commit -m "Test that nn auto-detect appends both Perl mixins"
```

---

## Task 9: Update `nono/CLAUDE.md` documentation

**Files:**
- Modify: `nono/CLAUDE.md`
- Test: `markdownlint-cli nono/CLAUDE.md` (if available), manual read-through

Document the core/net split and the opt-in permissive profile, and fix every now-stale reference. The reorg moves the always-on siblings and the cross-cutting blocks out of `oalders.json` into `oalders-core`, and all network into `*-net` siblings — several sections currently say otherwise.

- [ ] **Step 1: Update the "Files" list**

In the `## Files` section, add bullets describing the new always-on composition. After the `oalders.json` bullet, add:

```markdown
- `oalders-core.json` — net-free shared base (always-on MCP/runtime siblings, security policy, cross-cutting filesystem grants), symlinked to `~/.config/nono/profiles/oalders-core.json`
- `oalders-net.json` — all outbound network rules for the default chain (curated `allow_domain`, `open_port`, `network_profile: null`), symlinked to `~/.config/nono/profiles/oalders-net.json`
```

Also change the `oalders.json` bullet's description to reflect that it is now a composition root: replace "nono profile" with "nono profile composition root (`extends: [oalders-core, oalders-net]`)".

- [ ] **Step 2: Add a "Core/net split" subsection under "Sibling profiles"**

Immediately under the `## Sibling profiles` intro paragraph (before `### Always-on`), insert:

```markdown
### Net-free base vs. network siblings

`oalders` is now `{"extends": ["oalders-core", "oalders-net"]}`:

- **`oalders-core`** holds the always-on siblings, the `security` block, and the cross-cutting `filesystem` grants — and **no `network`**.
- **`oalders-net`** holds *all* outbound rules: the curated `allow_domain` list, `open_port`, the defensive `network_profile: null`, and uv's PyPI domains.

The rule that forces this split: nono's `extends` is append-only, and **any** `allow_domain` anywhere in the chain flips nono into proxy allowlist mode (default-deny outbound). There is no way to remove an inherited domain. So every grant sibling (filesystem/runtime) is kept net-free, and all domains/ports live in dedicated `*-net` siblings. A profile that needs open network — like `oalders-perl-test` — composes only net-free grants and adds no `*-net`, leaving outbound and localhost ports unrestricted.
```

- [ ] **Step 3: Fix the "Always-on" heading and intro**

In `### Always-on (mixed in via `oalders.json`'s own `extends`)`, change the heading and its intro paragraph to attribute the always-on siblings to `oalders-core`, not `oalders.json`. Replace the heading with:

```markdown
### Always-on (mixed in via `oalders-core`'s `extends`)
```

And replace the intro sentence "so they go in `oalders.json`'s `extends` list rather than per-repo detection." with "so they go in `oalders-core`'s `extends` list (which `oalders` always pulls in) rather than per-repo detection."

- [ ] **Step 4: Fix the `oalders-uv` row in the Always-on table**

In the Always-on table, change the `oalders-uv` row's "Owns" cell from:

```markdown
| `oalders-uv`        | `~/.local/share/uv` (uv runtime — used by `uvx` and `uv tool install`)                 |
```

to:

```markdown
| `oalders-uv`        | `~/.local/share/uv` (uv runtime — used by `uvx` and `uv tool install`). Net-free; PyPI domains live in `oalders-net`. |
```

- [ ] **Step 5: Fix the `oalders-perl` row in the Project-detected table**

In the Project-detected table, change the `oalders-perl` row's "Owns" cell to drop the network claim and point at the new sibling. Replace:

```markdown
| `oalders-perl`  | `cpanfile`, `Makefile.PL`, `dist.ini` | plenv (`~/.plenv`), local::lib (`~/perl5`), Dist::Zilla (`~/.dzil`, `~/dot-files/dzil`), prove (`~/.proverc`), CPAN/MagPie network, XS system C headers (`/usr/include`, `/usr/local/include`) |
```

with:

```markdown
| `oalders-perl`  | `cpanfile`, `Makefile.PL`, `dist.ini` | plenv (`~/.plenv`), local::lib (`~/perl5`), Dist::Zilla (`~/.dzil`, `~/dot-files/dzil`), prove (`~/.proverc`), XS system C headers (`/usr/include`, `/usr/local/include`). Net-free; CPAN/MetaCPAN/MagPie network is in the paired `oalders-perl-net` (appended alongside it by `nn`). |
```

- [ ] **Step 6: Document `oalders-perl-test` in the "Opt-in only" section**

In `### Opt-in only (no auto-detection)`, add a row to the opt-in table and an invocation note. Add this row after the `oalders-terraform` row:

```markdown
| `oalders-perl-test` | Open outbound network + unrestricted localhost ports (no `allow_domain`/`open_port` in its chain), with `oalders-core` + `oalders-perl` grants and the full filesystem lockdown. For CPAN test suites needing live network or `Test::TCP`-style ephemeral ports. |
```

And after the existing terraform `.nono/profile.json` example, add:

```markdown
`oalders-perl-test` is invoked directly rather than via a per-repo wrapper, because it intentionally drops the network/port restrictions a wrapper extending `oalders` would re-impose:

```
nn --profile oalders-perl-test
```
```

- [ ] **Step 7: Repoint the "Cross-cutting" guidance in "Extending the profile"**

In `## Extending the profile`, step 2, the "Cross-cutting" bullet currently says "→ `oalders.json`". Change it to "→ `oalders-core.json` (the net-free base). New network domains/ports → `oalders-net.json`."

- [ ] **Step 8: Repoint the "Cross-cutting bits" subsection**

Change the `### Cross-cutting bits that stay in `oalders.json`` heading to:

```markdown
### Cross-cutting bits that live in `oalders-core.json`
```

and update its intro sentence "so they live in the base:" → "so they live in `oalders-core` (the net-free base that `oalders` always extends):". The bullet list of paths is unchanged (those grants moved verbatim into `oalders-core`).

- [ ] **Step 9: Lint and read through**

Run: `markdownlint-cli nono/CLAUDE.md` (skip if the tool isn't installed).
Expected: no errors. Then re-read the file to confirm no remaining sentence claims `oalders.json` directly owns `extends`/`security`/`filesystem`/`network`.

- [ ] **Step 10: Commit**

```bash
git add nono/CLAUDE.md
git commit -m "Document core/net profile split and oalders-perl-test"
```

---

## Final verification

- [ ] **Step 1: Validate every touched profile once more**

Run:
```bash
for p in oalders oalders-core oalders-net oalders-uv oalders-perl oalders-perl-net oalders-perl-test; do
  echo "== $p =="
  nono policy validate ~/.config/nono/profiles/$p.json
done
```
Expected: all validate OK.

- [ ] **Step 2: Re-run the issue-#948 regression and the full nn suite**

Run:
```bash
bin/test-nono-claude-md.sh
bats test/nn.bats
```
Expected: the first prints `ok: ...`; the second reports 0 failures.

- [ ] **Step 3: Lint shell**

Run: `precious lint` (or `shfmt -d -s -i 4 bin/nn installer/symlinks.sh`)
Expected: no diffs / no lint errors on the touched shell files.
```
