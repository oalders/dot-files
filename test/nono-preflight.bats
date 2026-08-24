#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    PREFLIGHT="$BIN_DIR/nono-preflight"
}

# Stub nono with per-subcommand behavior. Args:
#   $1 = value for the "Supported:" line of `why --scope signal` (true|false)
#   $2 = "Reason:" value for `why --host ...` (e.g. proxy_filtered|network_allowed)
stub_nono() {
    local supported="$1" reason="$2"
    stub_command nono "case \"\$*\" in
    'why --scope signal') echo '  State: unsupported'; echo '  Supported: $supported'; echo '  Kernel ABI: V4' ;;
    'why --host '*) echo 'DENIED'; echo '  Reason: $reason' ;;
    '--version') echo 'nono 0.74.0' ;;
    *) exit 0 ;;
esac"
}

@test "nono-preflight blocks when signal scoping is unsupported and the profile is proxy-supervised" {
    stub_nono false proxy_filtered
    run "$PREFLIGHT" oalders
    [ "$status" -eq 1 ]
    # The diagnostic names the real cause and both remedies.
    [[ "$output" == *"Landlock ABI V6"* ]]
    [[ "$output" == *"upgrade-to-hwe-kernel.sh"* ]]
    [[ "$output" == *"v0.73.0"* ]]
    [[ "$output" == *"issues/1024"* ]]
    # And it names the resolved profile it refused.
    [[ "$output" == *"oalders"* ]]
}

@test "nono-preflight proceeds when the kernel supports signal scoping (Landlock V6)" {
    # V6 kernel: `nono why --host` should not even be consulted, but stub it
    # as proxy_filtered to prove signal support alone is enough to pass.
    stub_nono true proxy_filtered
    run "$PREFLIGHT" oalders
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "nono-preflight proceeds for a direct-network profile even on an old kernel" {
    # Signal scoping unsupported, but the profile allows network directly
    # (no filtering proxy), so it never enters supervised mode and survives.
    stub_nono false network_allowed
    run "$PREFLIGHT" oalders-perl
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "nono-preflight fails open when the scope query errors" {
    # A nono that errors on the scope query must not be read as "unsupported".
    stub_command nono 'case "$*" in
    "why --scope signal") echo "boom" >&2; exit 1 ;;
    *) exit 0 ;;
esac'
    run "$PREFLIGHT" oalders
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "nono-preflight fails open when no profile is given" {
    stub_nono false proxy_filtered
    run "$PREFLIGHT"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "nono-preflight fails open when nono is not installed" {
    # Restrict PATH to the stub dir plus the coreutils the helper needs, with
    # no nono present, to exercise the `command -v nono` fail-open branch.
    local toolbin="$BATS_TEST_TMPDIR/toolbin"
    mkdir -p "$toolbin"
    for tool in bash awk grep uname cat; do
        ln -sf "$(command -v "$tool")" "$toolbin/$tool"
    done
    PATH="$toolbin" run "$PREFLIGHT" oalders
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
