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
