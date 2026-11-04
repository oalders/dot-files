#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    REAL_FZF="$(command -v fzf)"
    export REAL_FZF
    setup_sandbox
    unset TMUX
    TMUX_LOG="$BATS_TEST_TMPDIR/tmux.log"
    export TMUX_LOG
    stub_command tmux '
case "$1" in
has-session) exit 0 ;;
list-sessions)
    echo "muevelo/fix-2001     Node 8 to 6 on 2 hosts"
    echo "muevelo/fix-1861     Fast image pins Node 2651 but the repo"
    echo "muevelo/fix-1862     Load-sensitive fast tests still fail make"
    ;;
*) echo "$*" >>"$TMUX_LOG" ;;
esac'
}

@test "a direct match outranks scattered ones, even with small gaps" {
    # Real fzf ranking with a canned query, keeping the top result.
    stub_command fzf '"$REAL_FZF" "$@" --filter=862 | head -1'

    run "$BIN_DIR/tm"

    [ "$status" -eq 0 ]
    [ "$(cat "$TMUX_LOG")" = "attach-session -t muevelo/fix-1862     Load-sensitive fast tests still fail make" ]
}

@test "switches rather than attaches when already inside tmux" {
    export TMUX=fake
    stub_command fzf '"$REAL_FZF" "$@" --filter=862 | head -1'

    run "$BIN_DIR/tm"

    [ "$status" -eq 0 ]
    [ "$(cat "$TMUX_LOG")" = "switch-client -t muevelo/fix-1862     Load-sensitive fast tests still fail make" ]
}

@test "cancelling the picker leaves tmux alone" {
    stub_command fzf 'exit 130'

    run "$BIN_DIR/tm"

    [ "$status" -eq 0 ]
    [[ "$output" == *"No session selected"* ]]
    [ ! -e "$TMUX_LOG" ]
}
