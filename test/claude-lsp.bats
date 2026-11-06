#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME/.local/bin"
    ln -s "$SCRIPT_DIR" "$HOME/dot-files"
    CALLS="$BATS_TEST_TMPDIR/claude-calls"
    export CALLS
    # Defaults to nothing installed: empty plugin list, `mcp get` fails.
    stub_command claude 'echo "$*" >>"$CALLS"
case "$*" in
"plugin list --json") echo "${PLUGIN_LIST:-[]}" ;;
"mcp get serena") [[ -n ${MCP_GET:-} ]] || exit 1; echo "$MCP_GET" ;;
esac'
    UVX="$HOME/.local/bin/uvx"
}

@test "nothing to clean up: exits 0 without uninstalling or removing" {
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    grep -Fxq "plugin marketplace add $HOME/dot-files/claude-plugins" "$CALLS"
    grep -Fxq "plugin install bash-perl-lsp@dot-files" "$CALLS"
    ! grep -Eq "uninstall|mcp remove" "$CALLS"
}

@test "user-scope serena plugin is uninstalled" {
    export PLUGIN_LIST='[{"id":"serena@claude-plugins-official","scope":"user"}]'
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    grep -Fxq "plugin uninstall serena@claude-plugins-official" "$CALLS"
}

@test "project-scope serena plugin is left alone" {
    export PLUGIN_LIST='[{"id":"serena@claude-plugins-official","scope":"project"}]'
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    run grep -q uninstall "$CALLS"
    [ "$status" -eq 1 ]
}

@test "user-scope serena MCP server is removed" {
    export MCP_GET='  Scope: User config (available in all your projects)'
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    grep -Fxq "mcp remove -s user serena" "$CALLS"
}

@test "non-user-scope serena MCP server is left alone" {
    export MCP_GET='  Scope: Local config (private to you in this project)'
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    run grep -q "mcp remove" "$CALLS"
    [ "$status" -eq 1 ]
}

@test "serena shim present: real uvx is restored" {
    echo 'exec serena-mcp-server # oraios/serena' >"$UVX"
    echo real >"$UVX.real"
    run "$SCRIPT_DIR/configure/claude-lsp.sh"
    [ "$status" -eq 0 ]
    [ "$(cat "$UVX")" = real ]
    [ ! -e "$UVX.real" ]
}

@test "only uvx.real present: real uvx is restored" {
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
