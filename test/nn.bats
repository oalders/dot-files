#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    NN="$BIN_DIR/nn"
    # Isolate from the dev's real ~/.config/nono and from any surrounding
    # git repo (so the walk-up in bin/nn doesn't leak into the test
    # runner's actual project).
    HOME="$BATS_TEST_TMPDIR/home"
    export HOME
    export GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR"
    mkdir -p "$HOME/.config/nono"
    # bin/nn reads this with jq; needs to be valid JSON.
    echo '{"sandbox":{"enabled":false}}' > "$HOME/.config/nono/claude-settings.json"
    # bin/nn cp's this seed into the worktree-local serena home; only
    # existence matters for the test.
    echo '{}' > "$HOME/.config/nono/serena_config.yml"
    # Stub nono to dump its argv to a file we can grep.
    stub_command nono 'printf "%s\n" "$@" > "$BATS_TEST_TMPDIR/nono-argv"'
    # Clean cwd outside any git work tree.
    mkdir -p "$BATS_TEST_TMPDIR/work"
    cd "$BATS_TEST_TMPDIR/work"
}

@test "bin/nn injects NPM_CONFIG_CACHE pointing at \$PWD/.tmp/cache/npm" {
    run "$NN"
    [ "$status" -eq 0 ]
    grep -Fxq "NPM_CONFIG_CACHE=$BATS_TEST_TMPDIR/work/.tmp/cache/npm" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn detects Hugo via the modular config/_default/ layout" {
    # Detection keys on the config/_default/ directory existing, not on the
    # file inside it; the hugo.toml here just mirrors a real modular-layout
    # site so the fixture reads true to what it represents.
    mkdir -p config/_default
    echo 'baseURL = "https://example.com/"' > config/_default/hugo.toml
    run "$NN"
    [ "$status" -eq 0 ]
    [ -f .nono/profile.json ]
    grep -Fq '"oalders-hugo"' .nono/profile.json
    grep -Fq '"oalders-snap"' .nono/profile.json
}

@test "bin/nn does not detect Hugo when no config is present" {
    run "$NN"
    [ "$status" -eq 0 ]
    # No stack detected: bin/nn falls back to the bare oalders profile and
    # writes no .nono/profile.json wrapper.
    [ ! -f .nono/profile.json ]
}

@test "bin/nn --clodhopper runs clodhopper init --local" {
    # Stub clodhopper to record its argv so we can assert how it was invoked.
    stub_command clodhopper 'printf "%s\n" "$@" > "$BATS_TEST_TMPDIR/clodhopper-argv"'
    run "$NN" --clodhopper
    [ "$status" -eq 0 ]
    [ -f "$BATS_TEST_TMPDIR/clodhopper-argv" ]
    grep -Fxq -- "init" "$BATS_TEST_TMPDIR/clodhopper-argv"
    grep -Fxq -- "--local" "$BATS_TEST_TMPDIR/clodhopper-argv"
}

@test "bin/nn --clodhopper is consumed, not forwarded to claude" {
    stub_command clodhopper 'true'
    run "$NN" --clodhopper
    [ "$status" -eq 0 ]
    # The nn-specific flag must be parsed out of $@, not passed through to claude.
    ! grep -Fxq -- "--clodhopper" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn --clodhopper is parsed out independently of forwarded args" {
    stub_command clodhopper 'true'
    run "$NN" --clodhopper --resume
    [ "$status" -eq 0 ]
    # The nn-specific flag is consumed; the unrelated arg still reaches claude.
    ! grep -Fxq -- "--clodhopper" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "--resume" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn does not run clodhopper without the flag" {
    # If clodhopper were invoked, this stub would fail the test by exiting 1.
    stub_command clodhopper 'echo "clodhopper should not run" >&2; exit 1'
    run "$NN"
    [ "$status" -eq 0 ]
    [ ! -f "$BATS_TEST_TMPDIR/clodhopper-argv" ]
}

@test "bin/nn hands claude the queued prompt and consumes the marker" {
    mkdir -p .tmp
    printf '%s\n' '/kitchen-sink:fix-gh-issue' >.tmp/fix-gh-issue.pending
    run "$NN"
    [ "$status" -eq 0 ]
    # The queued slash command reaches claude as its initial prompt.
    grep -Fxq '/kitchen-sink:fix-gh-issue' "$BATS_TEST_TMPDIR/nono-argv"
    # The marker is one-shot: consumed on the first launch.
    [ ! -f .tmp/fix-gh-issue.pending ]
}

@test "bin/nn does not re-run the queued prompt after the marker is consumed" {
    mkdir -p .tmp
    printf '%s\n' '/kitchen-sink:fix-gh-issue' >.tmp/fix-gh-issue.pending
    run "$NN"
    [ "$status" -eq 0 ]
    # Second launch in the same worktree: the marker is gone, so the prompt
    # must not fire again.
    : >"$BATS_TEST_TMPDIR/nono-argv"
    run "$NN"
    [ "$status" -eq 0 ]
    ! grep -Fxq '/kitchen-sink:fix-gh-issue' "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn injects nothing for an empty marker but still consumes it" {
    # Baseline: the claude argv with no marker at all.
    run "$NN"
    [ "$status" -eq 0 ]
    cp "$BATS_TEST_TMPDIR/nono-argv" "$BATS_TEST_TMPDIR/nono-argv.baseline"

    # An empty marker holds no prompt: the `[[ -n $pending_prompt ]]` guard
    # must suppress injection so the claude invocation is byte-for-byte the
    # baseline (no stray empty positional appended) — yet the one-shot
    # marker is still consumed. Comparing full argv (not just grepping for
    # the slash command) is what catches an empty-string arg leaking through.
    mkdir -p .tmp
    : >.tmp/fix-gh-issue.pending
    run "$NN"
    [ "$status" -eq 0 ]
    diff "$BATS_TEST_TMPDIR/nono-argv" "$BATS_TEST_TMPDIR/nono-argv.baseline"
    [ ! -f .tmp/fix-gh-issue.pending ]
}

@test "bin/nn passes no auto-prompt without the marker" {
    run "$NN"
    [ "$status" -eq 0 ]
    ! grep -Fxq '/kitchen-sink:fix-gh-issue' "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn skips the queued prompt when the user supplies their own" {
    mkdir -p .tmp
    printf '%s\n' '/kitchen-sink:fix-gh-issue' >.tmp/fix-gh-issue.pending
    run "$NN" "do something else"
    [ "$status" -eq 0 ]
    # The user's prompt reaches claude; the queued one is suppressed.
    grep -Fxq 'do something else' "$BATS_TEST_TMPDIR/nono-argv"
    ! grep -Fxq '/kitchen-sink:fix-gh-issue' "$BATS_TEST_TMPDIR/nono-argv"
    # The one-shot marker is still consumed on the first launch.
    [ ! -f .tmp/fix-gh-issue.pending ]
}
