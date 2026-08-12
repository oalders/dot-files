#!/usr/bin/env bats

load 'helpers.bash'

# helpers.bash sets SCRIPT_DIR to the repo root (test/..).
NONO_DIR="$SCRIPT_DIR/nono"
SYMLINKS="$SCRIPT_DIR/installer/symlinks.sh"

# Every nono/oalders*.json profile must be symlinked into
# ~/.config/nono/profiles/ by installer/symlinks.sh. nono resolves a
# profile's `extends` entries by name from that directory, so a sibling
# that ships without a matching symlink line resolves to nothing on a
# fresh install (e.g. #969: oalders-playwright-net would be invisible to
# the oalders chain). This guards against adding a profile and forgetting
# the symlink.
@test "every nono/oalders*.json profile is symlinked by installer/symlinks.sh" {
    local missing=()
    local path base
    for path in "$NONO_DIR"/oalders*.json; do
        base="$(basename "$path")"
        # Match the exact install target: a line linking this file into the
        # profiles dir. -F so the wildcard-free literal matches verbatim.
        if ! grep -Fq "/nono/$base ~/.config/nono/profiles/$base" "$SYMLINKS"; then
            missing+=("$base")
        fi
    done
    [ "${#missing[@]}" -eq 0 ] || {
        printf 'profiles missing a symlinks.sh entry: %s\n' "${missing[*]}"
        false
    }
}

# The composition root must pull the Playwright download CDN hosts into the
# default chain via the dedicated net sibling — not into oalders-playwright
# itself, which is net-free so the permissive open-network profiles
# (oalders-open, oalders-perl-test) don't inherit an allowlist (#969).
@test "oalders-playwright.json carries no network rules (stays net-free)" {
    run grep -Fq '"network"' "$NONO_DIR/oalders-playwright.json"
    [ "$status" -ne 0 ]
}

@test "oalders.json extends oalders-playwright-net" {
    run grep -Fq '"oalders-playwright-net"' "$NONO_DIR/oalders.json"
    [ "$status" -eq 0 ]
}

@test "oalders-playwright-net.json allows the Playwright download CDN hosts" {
    local host
    # storage.googleapis.com is the Chrome for Testing redirect target that the
    # `chromium` build resolves to (cdn.playwright.dev 307s to it); without it,
    # `playwright install chromium` 403s at the redirected GCS host (#969).
    for host in cdn.playwright.dev playwright.download.prss.microsoft.com playwright.azureedge.net storage.googleapis.com; do
        grep -Fq "\"$host\"" "$NONO_DIR/oalders-playwright-net.json" || {
            printf 'missing allow_domain entry: %s\n' "$host"
            false
        }
    done
}

# Full Chrome writes its crash database to ~/.config/google-chrome/Crash
# Reports (a fixed path, not under --user-data-dir), which the claude-code
# base denies via deny_browser_data_linux. Without a writable crash dir the
# crashpad handler aborts ("--database is required") and the browser SIGTRAPs
# on startup under the sandbox (#970). The fix grants that subdir AND
# bypass-protects it — nono rejects a bypass_protection path that lacks a
# matching grant, so the two must travel together.
@test "oalders-chrome.json grants the crashpad Crash Reports dir" {
    run grep -Fq '"~/.config/google-chrome/Crash Reports"' "$NONO_DIR/oalders-chrome.json"
    [ "$status" -eq 0 ]
}

@test "oalders-chrome.json bypass-protects the Crash Reports dir it grants" {
    # nono: bypass_protection only removes the deny; it must be paired with an
    # allow/read/write grant for the same path or the sandbox refuses to start.
    run jq -e '
        (.filesystem.bypass_protection // []) as $b
        | (.filesystem.allow // []) as $a
        | ($b | index("~/.config/google-chrome/Crash Reports")) != null
          and ($a | index("~/.config/google-chrome/Crash Reports")) != null
    ' "$NONO_DIR/oalders-chrome.json"
    [ "$status" -eq 0 ]
}

# The grant must stay scoped to the Crash Reports subdir. Granting the parent
# ~/.config/google-chrome (or bypassing it) would expose the sibling Default/
# dir, where cookies, saved passwords, and sessions live — exactly what
# deny_browser_data_linux protects.
@test "oalders-chrome.json does not grant the whole google-chrome data dir" {
    run jq -e '
        [.filesystem.allow[]?, .filesystem.read[]?, .filesystem.bypass_protection[]?]
        | any(. == "~/.config/google-chrome" or . == "~/.config/google-chrome/")
    ' "$NONO_DIR/oalders-chrome.json"
    # jq -e exits non-zero when the result is false/null: that is the pass.
    [ "$status" -ne 0 ]
}

# oalders-chrome is composed into oalders-core, which the permissive
# open-network profiles also extend — so it must stay net-free (no network
# rules), the same invariant the playwright sibling holds (#969).
@test "oalders-chrome.json carries no network rules (stays net-free)" {
    run grep -Fq '"network"' "$NONO_DIR/oalders-chrome.json"
    [ "$status" -ne 0 ]
}

# Regression guard for #991. The full `ansible` pipx package installs its venv
# at venvs/ansible — that's where the ~/.local/bin/ansible* entrypoints resolve.
# The issue proposed renaming the grant to venvs/ansible-core (the name pipx
# uses for `pipx install ansible-core`), which would point the read at a path
# that does not exist for this setup and leave every ansible binary unreadable
# (errno 13) under the sandbox. Pin the correct venv name and reject the rename.
@test "oalders-ansible.json reads the ansible venv, not ansible-core" {
    run jq -e '.filesystem.read | any(. == "~/.local/share/pipx/venvs/ansible")' "$NONO_DIR/oalders-ansible.json"
    [ "$status" -eq 0 ]
    run jq -e '.filesystem.read | any(. == "~/.local/share/pipx/venvs/ansible-core")' "$NONO_DIR/oalders-ansible.json"
    # jq -e exits non-zero when the result is false/null: that is the pass.
    [ "$status" -ne 0 ]
}

# A real playbook run using user-installed Galaxy collections needs
# ~/.ansible/collections readable — they install outside the venv (#991).
@test "oalders-ansible.json grants the Galaxy collections read path" {
    run jq -e '.filesystem.read | any(. == "~/.ansible/collections")' "$NONO_DIR/oalders-ansible.json"
    [ "$status" -eq 0 ]
}

# oalders-ansible is filesystem-only by design: SSH egress to deploy targets is
# out of scope, and the controller temp is redirected to a granted scratch base
# by bin/nn rather than granted here. It must carry no network rules so nothing
# composing it inherits an allowlist (the same invariant the other siblings hold).
@test "oalders-ansible.json carries no network rules (stays net-free)" {
    run grep -Fq '"network"' "$NONO_DIR/oalders-ansible.json"
    [ "$status" -ne 0 ]
}

# The actual #1002 bug, and the only load-bearing grant in the mixin: `docker
# compose` and `docker buildx` are CLI *plugins* — standalone binaries under
# /usr/libexec/docker/cli-plugins that the docker binary execs by path, not
# subcommands of it. Without a read grant on that dir those two commands fail
# with "docker: unknown command" even though `docker` itself runs fine.
@test "oalders-docker.json grants the docker CLI plugins dir" {
    run jq -e '.filesystem.read | any(. == "/usr/libexec/docker/cli-plugins")' "$NONO_DIR/oalders-docker.json"
    [ "$status" -eq 0 ]
}

# The grant is narrowed to cli-plugins/ rather than the whole
# /usr/libexec/docker tree, which also carries daemon-side helpers the CLI
# never needs. Guard the narrowing so it can't silently widen back (#1002).
@test "oalders-docker.json does not grant the whole /usr/libexec/docker dir" {
    # Parse first. jq -e exits 2 on a missing or malformed file, which is
    # indistinguishable from "predicate was false" (exit 1) — without this, the
    # guard below would go green if the profile were deleted or corrupted.
    run jq empty "$NONO_DIR/oalders-docker.json"
    [ "$status" -eq 0 ]
    # Reject any ancestor of cli-plugins/, across every filesystem grant key —
    # widening to /usr/libexec or /usr would defeat a check pinned to the one
    # exact string, and a widening added under *_file or bypass_protection
    # would be invisible to a check that only reads allow/read.
    # $e binds the element before the `| startswith` pipe, which would
    # otherwise rebind `.` to $want and silently compare $want against itself.
    run jq -e --arg want /usr/libexec/docker/cli-plugins '
        [.filesystem.allow[]?, .filesystem.read[]?,
         .filesystem.allow_file[]?, .filesystem.read_file[]?,
         .filesystem.bypass_protection[]?]
        | map(sub("/$"; ""))
        | any(. as $e | $e != $want and ($want | startswith($e + "/")))
    ' "$NONO_DIR/oalders-docker.json"
    # jq -e exits non-zero when the result is false/null: that is the pass.
    [ "$status" -ne 0 ]
}

# These two entries are DEFENSIVE and NOT load-bearing: they are not what lets
# the CLI reach the daemon. Landlock mediates path open(), not connect(AF_UNIX),
# so the daemon socket is reachable from every nono session regardless of
# profile — verified: `nono why --path /run/docker.sock --op write --profile
# oalders` reports DENIED / path_not_granted while `docker ps` in that same
# session still talks to the host daemon. The grants are kept (and asserted
# here) purely so the profile is correct-by-construction should nono ever
# mediate socket connect, and so it stays portable to layouts where /var/run is
# not a symlink to /run (on Linux it is, and nono reports the resolved path).
# This test asserts presence only; it makes no containment claim (#1002).
@test "oalders-docker.json keeps both docker socket paths as defensive grants" {
    local sock
    for sock in /var/run/docker.sock /run/docker.sock; do
        jq -e --arg s "$sock" '.filesystem.allow_file | any(. == $s)' "$NONO_DIR/oalders-docker.json" >/dev/null || {
            printf 'missing allow_file entry: %s\n' "$sock"
            false
        }
    done
}

# Buildx state is deliberately NOT granted at the home path anymore. Granting
# ~/.docker/buildx for write was a channel out of the sandbox: a session could
# persist a remote-driver builder aimed at an attacker endpoint and a later
# un-sandboxed `docker buildx build` on the host would ship its build context
# there, surviving worktree deletion. bin/nn redirects the state into the
# worktree via BUILDX_CONFIG instead (#1004; see the nn.bats redirect test).
@test "oalders-docker.json does not grant ~/.docker/buildx (redirected via BUILDX_CONFIG)" {
    # Parse first so a vanished profile fails loudly rather than passing vacuously.
    run jq empty "$NONO_DIR/oalders-docker.json"
    [ "$status" -eq 0 ]
    # Reject the path under any write-granting key, in either ~ or $HOME spelling.
    run jq -e '
        [.filesystem.allow[]?, .filesystem.allow_file[]?,
         .filesystem.bypass_protection[]?]
        | any(. == "~/.docker/buildx" or . == "$HOME/.docker/buildx")
    ' "$NONO_DIR/oalders-docker.json"
    # jq -e exits non-zero when the result is false/null: that is the pass.
    [ "$status" -ne 0 ]
}

# ~/.docker is deliberately narrowed to contexts/ and config.json rather than a
# directory-wide read: the tree can also hold credential helper output and other
# daemon/registry state (#1002). Buildx state used to sit here too but is now
# redirected to the worktree (#1004).
@test "oalders-docker.json does not grant the whole ~/.docker dir" {
    # Parse first — see the /usr/libexec guard above for why.
    run jq empty "$NONO_DIR/oalders-docker.json"
    [ "$status" -eq 0 ]
    # Directory grants only: config.json is deliberately granted as a single
    # file (read_file), so *_file keys are excluded here. $HOME and ~ are both
    # rejected, since either spelling would re-widen the grant.
    run jq -e '
        [.filesystem.allow[]?, .filesystem.read[]?,
         .filesystem.bypass_protection[]?]
        | map(sub("/$"; ""))
        | any(. == "~/.docker" or . == "$HOME/.docker"
              or . == "~" or . == "$HOME")
    ' "$NONO_DIR/oalders-docker.json"
    # jq -e exits non-zero when the result is false/null: that is the pass.
    [ "$status" -ne 0 ]
}

# Image pulls are performed by the daemon, which runs OUTSIDE the sandbox, so
# nothing docker does traverses the session proxy. The mixin must stay
# net-free like every other oalders-* sibling (#1002).
@test "oalders-docker.json carries no network rules (stays net-free)" {
    # Parse first: grep -Fq also exits non-zero on a missing file, so without
    # this the assertion below would pass vacuously if the profile vanished.
    # (The sibling net-free tests above share that gap; fixed here only, since
    # widening the change would put unrelated profiles in this diff.)
    run jq empty "$NONO_DIR/oalders-docker.json"
    [ "$status" -eq 0 ]
    run grep -Fq '"network"' "$NONO_DIR/oalders-docker.json"
    [ "$status" -ne 0 ]
}
