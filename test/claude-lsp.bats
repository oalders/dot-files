#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME/.local/bin"
    ln -s "$SCRIPT_DIR" "$HOME/dot-files"
    CALLS="$BATS_TEST_TMPDIR/claude-calls"
    export CALLS
    # Nothing installed: empty plugin list, `mcp get` fails.
    stub_command claude 'echo "$*" >>"$CALLS"
case "$*" in
"plugin list --json") echo "[]" ;;
"mcp get serena") exit 1 ;;
esac'
    UVX="$HOME/.local/bin/uvx"
}

@test "nothing to clean up: exits 0 without uninstalling or removing" {
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    grep -Fxq "plugin install bash-perl-lsp@dot-files" "$CALLS"
    ! grep -Eq "uninstall|mcp remove" "$CALLS"
}

@test "serena shim present: real uvx is restored" {
    echo 'exec serena-mcp-server # oraios/serena' >"$UVX"
    echo real >"$UVX.real"
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    [ "$(cat "$UVX")" = real ]
    [ ! -e "$UVX.real" ]
}

@test "newer real uvx in place: stale uvx.real is removed" {
    echo new >"$UVX"
    echo old >"$UVX.real"
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    [ "$(cat "$UVX")" = new ]
    [ ! -e "$UVX.real" ]
}
