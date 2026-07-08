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
    # Default to "no tailscale IP" so Hugo detection doesn't probe the real
    # host (which would leak the runner's tailscale IP into argv and make
    # tests non-hermetic). The Hugo-over-tailscale test overrides tailscale.
    stub_command tailscale 'exit 0'
    stub_command ip 'exit 0'
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
    # must not fire again. Reset the recorded argv before the second run so
    # the assertion sees only the second invocation's args (the stub uses `>`,
    # so this is belt-and-suspenders against a future append-style stub).
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

@test "bin/nn injects the queued prompt for a bare -- separator" {
    mkdir -p .tmp
    printf '%s\n' '/kitchen-sink:fix-gh-issue' >.tmp/fix-gh-issue.pending
    # `--` starts with `-`, so the heuristic treats `nn --` as flag-only and
    # still injects the queued prompt. Locks in the documented boundary.
    run "$NN" --
    [ "$status" -eq 0 ]
    grep -Fxq '/kitchen-sink:fix-gh-issue' "$BATS_TEST_TMPDIR/nono-argv"
    [ ! -f .tmp/fix-gh-issue.pending ]
}

@test "bin/nn suppresses the queued prompt for the documented --model opus misread" {
    mkdir -p .tmp
    printf '%s\n' '/kitchen-sink:fix-gh-issue' >.tmp/fix-gh-issue.pending
    # `nn --model opus` is the one shape the heuristic misreads: the separate-
    # word flag value `opus` looks like a user prompt, so injection is
    # suppressed even though no real prompt was given. This test locks in that
    # known limitation — if the heuristic is ever tightened to recognize flag
    # values, update the comment in bin/nn and flip this assertion deliberately.
    run "$NN" --model opus
    [ "$status" -eq 0 ]
    ! grep -Fxq '/kitchen-sink:fix-gh-issue' "$BATS_TEST_TMPDIR/nono-argv"
    # The one-shot marker is still consumed regardless of the misread.
    [ ! -f .tmp/fix-gh-issue.pending ]
}

@test "bin/nn passes no auto-prompt without the marker" {
    run "$NN"
    [ "$status" -eq 0 ]
    ! grep -Fxq '/kitchen-sink:fix-gh-issue' "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn --profile passes a non-file value through as a profile name" {
    run "$NN" --profile myprofile
    [ "$status" -eq 0 ]
    # The name lands as the value of nono's own --profile flag (the stub
    # dumps one arg per line, so the value is the line right after the
    # first --profile; -m1 keeps a forwarded duplicate from shadowing it).
    [ "$(grep -Fx -A1 -m1 -- '--profile' "$BATS_TEST_TMPDIR/nono-argv" | tail -n1)" = "myprofile" ]
    # And it reaches nono exactly once; a second occurrence would mean the
    # value leaked into the forwarded claude args.
    [ "$(grep -Fxc -- 'myprofile' "$BATS_TEST_TMPDIR/nono-argv")" -eq 1 ]
}

@test "bin/nn --profile resolves an existing file to an absolute path" {
    echo '{"extends": ["oalders"]}' > custom-profile.json
    run "$NN" --profile custom-profile.json
    [ "$status" -eq 0 ]
    grep -Fxq -- "$(realpath custom-profile.json)" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn supports the --profile=value form" {
    run "$NN" --profile=myprofile
    [ "$status" -eq 0 ]
    grep -Fxq -- "myprofile" "$BATS_TEST_TMPDIR/nono-argv"
    # The combined form is consumed, not forwarded to claude.
    ! grep -Fxq -- "--profile=myprofile" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn --profile without a value fails with exit 2" {
    run "$NN" --profile
    [ "$status" -eq 2 ]
    [[ "$output" == *"--profile requires a value"* ]]
    # nono must not be launched on a usage error.
    [ ! -f "$BATS_TEST_TMPDIR/nono-argv" ]
}

@test "bin/nn --profile= with an empty value fails with exit 2" {
    # `--profile=` matches the `--profile=*` glob with an empty value, which
    # the [[ -n $profile_override ]] guard would silently treat as no
    # override; it must error like the separate-word form instead.
    run "$NN" --profile=
    [ "$status" -eq 2 ]
    [[ "$output" == *"--profile requires a value"* ]]
    # nono must not be launched on a usage error.
    [ ! -f "$BATS_TEST_TMPDIR/nono-argv" ]
}

@test "bin/nn --profile '' with an empty value fails with exit 2" {
    # An explicitly empty separate-word value passes the argument-count
    # check, but the [[ -n $profile_override ]] guard would silently treat
    # it as no override; it must error like the missing-value form instead.
    run "$NN" --profile ""
    [ "$status" -eq 2 ]
    [[ "$output" == *"--profile requires a value"* ]]
    # nono must not be launched on a usage error.
    [ ! -f "$BATS_TEST_TMPDIR/nono-argv" ]
}

@test "bin/nn --profile is parsed out independently of forwarded args" {
    run "$NN" --profile myprofile --resume
    [ "$status" -eq 0 ]
    # The profile reaches nono as the value of its own --profile flag.
    [ "$(grep -Fx -A1 -m1 -- '--profile' "$BATS_TEST_TMPDIR/nono-argv" | tail -n1)" = "myprofile" ]
    # The unrelated arg still reaches claude.
    grep -Fxq -- "--resume" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn --profile overrides a discovered .nono/profile.json" {
    mkdir -p .nono
    echo '{"extends": ["oalders"]}' > .nono/profile.json
    run "$NN" --profile myprofile
    [ "$status" -eq 0 ]
    grep -Fxq -- "myprofile" "$BATS_TEST_TMPDIR/nono-argv"
    ! grep -Fxq -- "$BATS_TEST_TMPDIR/work/.nono/profile.json" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn --profile overrides stack auto-detection" {
    # package.json would normally trigger the oalders-node auto-detect and
    # write a .nono/profile.json wrapper; the override must skip both.
    echo '{}' > package.json
    run "$NN" --profile myprofile
    [ "$status" -eq 0 ]
    grep -Fxq -- "myprofile" "$BATS_TEST_TMPDIR/nono-argv"
    [ ! -f .nono/profile.json ]
}

@test "bin/nn grants /usr/bin/env to nono so override profiles can exec env" {
    # The sandboxed command starts with `env`; a --profile override that
    # doesn't extend the claude-code base would otherwise be unable to exec
    # it. The grant is unconditional, so assert it on a plain launch (the
    # stub dumps one arg per line, so the path is the line right after the
    # --read-file flag).
    run "$NN"
    [ "$status" -eq 0 ]
    [ "$(grep -Fx -A1 -m1 -- '--read-file' "$BATS_TEST_TMPDIR/nono-argv" | tail -n1)" = "/usr/bin/env" ]
}

@test "bin/nn --profile refuses a mixin that can't execute the claude binary" {
    # claude must resolve for the guard to run; stub it so the test doesn't
    # depend on a real install. nono why reports the resolved profile can't
    # read claude (the mixin footgun, #965), so the guard must refuse before
    # ever reaching `nono run`.
    stub_command claude 'true'
    stub_command nono 'if [ "$1" = why ]; then echo DENIED; exit 0; fi; printf "%s\n" "$@" > "$BATS_TEST_TMPDIR/nono-argv"'
    run "$NN" --profile oalders-perl
    [ "$status" -eq 1 ]
    [[ "$output" == *"can't execute the claude binary"* ]]
    # Refused before launching: nono run was never reached, so no argv dump.
    [ ! -f "$BATS_TEST_TMPDIR/nono-argv" ]
}

@test "bin/nn --profile proceeds when the profile can execute the claude binary" {
    # An ALLOWED verdict means the override extends the claude-code base; the
    # guard must let it through to nono run with the override profile intact.
    stub_command claude 'true'
    stub_command nono 'if [ "$1" = why ]; then echo ALLOWED; exit 0; fi; printf "%s\n" "$@" > "$BATS_TEST_TMPDIR/nono-argv"'
    run "$NN" --profile oalders
    [ "$status" -eq 0 ]
    [ "$(grep -Fx -A1 -m1 -- '--profile' "$BATS_TEST_TMPDIR/nono-argv" | tail -n1)" = "oalders" ]
}

@test "bin/nn --profile falls through to nono for an unknown profile name" {
    # nono why exits non-zero for an unknown profile, printing neither verdict.
    # The guard must NOT mistake that for a mixin: it falls through to nono
    # run, which surfaces its own profile-not-found error rather than the
    # misleading mixin warning. This is the deliberate divergence from #965's
    # `! ALLOWED` proposal — refuse only on an explicit DENIED.
    stub_command claude 'true'
    stub_command nono 'if [ "$1" = why ]; then exit 1; fi; printf "%s\n" "$@" > "$BATS_TEST_TMPDIR/nono-argv"'
    run "$NN" --profile no-such-profile
    [ "$status" -eq 0 ]
    [[ "$output" != *"can't execute the claude binary"* ]]
    grep -Fxq -- "no-such-profile" "$BATS_TEST_TMPDIR/nono-argv"
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

@test "bin/nn --chrome opens the pinned DevTools port and sets CHROME_WS_PORT" {
    # The superpowers-chrome MCP serves DevTools over a localhost TCP port the
    # default chain doesn't open. nn opens one fixed port (--open-port) and
    # pins the MCP to it (CHROME_WS_PORT) so the bind lands on the opened port
    # instead of a random one in the MCP's 9222-12111 range (#970).
    run "$NN" --chrome
    [ "$status" -eq 0 ]
    grep -Fxq -- "--open-port" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "9222" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "CHROME_WS_PORT=9222" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn --chrome pre-creates the crashpad Crash Reports dir" {
    # The oalders-chrome grant can't create the dir (its parent stays denied),
    # so nn seeds it outside the sandbox; without it full Chrome SIGTRAPs on
    # startup in the crashpad handler (#970).
    run "$NN" --chrome
    [ "$status" -eq 0 ]
    [ -d "$HOME/.config/google-chrome/Crash Reports" ]
}

@test "bin/nn without --chrome opens no DevTools port" {
    # The port and env pin stay scoped to --chrome sessions; opening the port
    # for every sandbox would needlessly widen idle and non-browser sessions.
    run "$NN"
    [ "$status" -eq 0 ]
    # Guard against a vacuous pass: if the stub never wrote the argv dump the
    # negative greps would "succeed" on a missing file and mask a regression.
    [ -f "$BATS_TEST_TMPDIR/nono-argv" ]
    ! grep -Fxq -- "--open-port" "$BATS_TEST_TMPDIR/nono-argv"
    ! grep -Fxq -- "CHROME_WS_PORT=9222" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn --chrome is consumed, not forwarded to claude" {
    # --chrome is an nn-specific flag: it must be parsed out of \$@, not passed
    # through to claude (which would reject the unknown flag).
    run "$NN" --chrome
    [ "$status" -eq 0 ]
    [ -f "$BATS_TEST_TMPDIR/nono-argv" ]
    ! grep -Fxq -- "--chrome" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn --playwright produces a launch that can actually use Playwright" {
    # "Usable" has two halves that must BOTH hold, so this asserts them together:
    #   1. the Playwright MCP is enabled in the session settings handed to claude
    #      (without it there is no Playwright to drive), and
    #   2. every localhost port a Playwright *test* run binds is opened. The MCP
    #      talks to the browser over a stdio pipe, but the tests bind TCP the
    #      default chain doesn't cover — the HTML report / trace viewer
    #      (preferredPort 9323, increments when busy) and a preview/webServer —
    #      so an unopened bind is Landlock-denied. nn opens the 9323-9342 block.
    run "$NN" --playwright
    [ "$status" -eq 0 ]
    [ "$(jq -r '.enabledPlugins["playwright@claude-plugins-official"]' .tmp/claude-settings.json)" = "true" ]
    # Exactly the 20-port block, no wider (over-opening needlessly widens the
    # sandbox) and no narrower (a missing port is a bind that still fails).
    [ "$(grep -Fxc -- "--open-port" "$BATS_TEST_TMPDIR/nono-argv")" -eq 20 ]
    # Spot-check both ends and the interior of the documented range.
    grep -Fxq -- "9323" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "9333" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "9342" "$BATS_TEST_TMPDIR/nono-argv"
    # And nothing just outside it.
    ! grep -Fxq -- "9322" "$BATS_TEST_TMPDIR/nono-argv"
    ! grep -Fxq -- "9343" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn auto-enables Playwright from a playwright.config.js marker" {
    # Detection keys on an e2e marker at the repo top, so a project that has
    # committed a Playwright config gets the MCP and its ports without --playwright.
    echo 'export default {};' > playwright.config.js
    run "$NN"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.enabledPlugins["playwright@claude-plugins-official"]' .tmp/claude-settings.json)" = "true" ]
    [ "$(grep -Fxc -- "--open-port" "$BATS_TEST_TMPDIR/nono-argv")" -eq 20 ]
    grep -Fxq -- "9323" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn without Playwright opens no Playwright ports and leaves the MCP off" {
    # The port block and MCP stay scoped to Playwright sessions; enabling them
    # for every sandbox would needlessly widen idle and non-e2e sessions. (The
    # clean test cwd has no e2e markers, so nothing auto-enables here.)
    run "$NN"
    [ "$status" -eq 0 ]
    # Guard against a vacuous pass on a missing argv dump.
    [ -f "$BATS_TEST_TMPDIR/nono-argv" ]
    [ "$(jq -r '.enabledPlugins["playwright@claude-plugins-official"]' .tmp/claude-settings.json)" = "false" ]
    [ "$(grep -Fxc -- "--open-port" "$BATS_TEST_TMPDIR/nono-argv")" -eq 0 ]
}

@test "bin/nn --playwright is consumed, not forwarded to claude" {
    # --playwright is an nn-specific flag: it must be parsed out of \$@, not
    # passed through to claude (which would reject the unknown flag).
    run "$NN" --playwright
    [ "$status" -eq 0 ]
    [ -f "$BATS_TEST_TMPDIR/nono-argv" ]
    ! grep -Fxq -- "--playwright" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn opens Hugo serve ports and wires the tailscale IP when one exists" {
    # A Hugo project on a tailnet host should be servable to other devices via
    # `hugo server --bind $TAILSCALE_IP`. That needs three things, asserted
    # together here: the serve ports opened for bind+listen, the IP exported as
    # $TAILSCALE_IP, and the IP added to NO_PROXY so in-sandbox inspection
    # (curl / the Playwright MCP) reaches the served site directly instead of
    # through the credential proxy.
    echo '{"baseURL": "https://example.com/"}' > hugo.json
    stub_command tailscale 'if [ "$1" = "ip" ]; then echo "100.72.160.52"; fi'
    run "$NN"
    [ "$status" -eq 0 ]
    # Exactly the 1313-1316 block, no wider and no narrower.
    [ "$(grep -Fxc -- "--open-port" "$BATS_TEST_TMPDIR/nono-argv")" -eq 4 ]
    grep -Fxq -- "1313" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "1316" "$BATS_TEST_TMPDIR/nono-argv"
    ! grep -Fxq -- "1312" "$BATS_TEST_TMPDIR/nono-argv"
    ! grep -Fxq -- "1317" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "TAILSCALE_IP=100.72.160.52" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "NO_PROXY=localhost,127.0.0.1,100.72.160.52" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "no_proxy=localhost,127.0.0.1,100.72.160.52" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn opens no Hugo ports when the host has no tailscale IP" {
    # The serve grant is scoped to hosts that actually have a tailscale IPv4
    # (the default setup() stubs make tailscale/ip return nothing). Without
    # one there is nothing to serve to, so the ports stay closed, NO_PROXY
    # keeps only loopback, and $TAILSCALE_IP is never set.
    echo '{"baseURL": "https://example.com/"}' > hugo.json
    run "$NN"
    [ "$status" -eq 0 ]
    [ "$(grep -Fxc -- "--open-port" "$BATS_TEST_TMPDIR/nono-argv")" -eq 0 ]
    ! grep -Fq -- "TAILSCALE_IP=" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "NO_PROXY=localhost,127.0.0.1" "$BATS_TEST_TMPDIR/nono-argv"
}

@test "bin/nn does not probe for a tailscale IP outside Hugo projects" {
    # The tailscale grant is Hugo-scoped: a non-Hugo sandbox opens no serve
    # ports and leaves NO_PROXY at loopback even if the host is on a tailnet.
    stub_command tailscale 'if [ "$1" = "ip" ]; then echo "100.72.160.52"; fi'
    run "$NN"
    [ "$status" -eq 0 ]
    [ "$(grep -Fxc -- "--open-port" "$BATS_TEST_TMPDIR/nono-argv")" -eq 0 ]
    ! grep -Fq -- "TAILSCALE_IP=" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "NO_PROXY=localhost,127.0.0.1" "$BATS_TEST_TMPDIR/nono-argv"
}
