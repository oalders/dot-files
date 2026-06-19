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
    for host in cdn.playwright.dev playwright.download.prss.microsoft.com playwright.azureedge.net; do
        grep -Fq "\"$host\"" "$NONO_DIR/oalders-playwright-net.json" || {
            printf 'missing allow_domain entry: %s\n' "$host"
            false
        }
    done
}
