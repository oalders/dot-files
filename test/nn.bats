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
