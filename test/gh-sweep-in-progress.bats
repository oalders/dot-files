#!/usr/bin/env bats

load 'helpers.bash'

# The gh stub logs each call's args (one per line, blank-line separated) and
# answers `gh search` with $BATS_TEST_TMPDIR/found, i.e. post---jq output.
setup() {
    setup_sandbox
    SWEEP="$BIN_DIR/gh-sweep-in-progress"
    stub_command gh '
printf "%s\n" "$@" "" >>"$BATS_TEST_TMPDIR/gh.log"
case "$1" in
    search)
        [[ -e "$BATS_TEST_TMPDIR/search-fails" ]] && exit 1
        cat "$BATS_TEST_TMPDIR/found" 2>/dev/null
        ;;
    issue) [[ "$3" == *fail* ]] && exit 1 ;;
esac
exit 0
'
}

@test "removes the exact-case label from each found issue" {
    printf 'https://x/1\tin progress\nhttps://x/2\tIn Progress\n' >"$BATS_TEST_TMPDIR/found"
    run "$SWEEP"
    [ "$status" -eq 0 ]
    [[ "$output" == *"removed 'in progress' label from https://x/1"* ]]
    [[ "$output" == *"removed 'In Progress' label from https://x/2"* ]]
    grep -qx -- "In Progress" "$BATS_TEST_TMPDIR/gh.log"
}

@test "searches closed, unarchived issues for the default owner" {
    run "$SWEEP"
    [ "$status" -eq 0 ]
    run grep -A1 -x -- --owner "$BATS_TEST_TMPDIR/gh.log"
    [ "$output" = "$(printf -- '--owner\noalders')" ]
    grep -qx -- --archived=false "$BATS_TEST_TMPDIR/gh.log"
    grep -A1 -x -- --state "$BATS_TEST_TMPDIR/gh.log" | grep -qx closed
}

@test "each --owner is passed as its own flag" {
    run "$SWEEP" --owner a --owner=b
    [ "$status" -eq 0 ]
    run grep -A1 -x -- --owner "$BATS_TEST_TMPDIR/gh.log"
    [ "$output" = "$(printf -- '--owner\na\n--owner\nb')" ]
}

@test "a failed edit exits 1 after processing the rest" {
    printf 'https://x/fail\tin progress\nhttps://x/2\tin progress\n' >"$BATS_TEST_TMPDIR/found"
    run "$SWEEP"
    [ "$status" -eq 1 ]
    [[ "$output" == *"warning: could not remove 'in progress' label from https://x/fail"* ]]
    [[ "$output" == *"removed 'in progress' label from https://x/2"* ]]
}

@test "a failed search exits non-zero" {
    : >"$BATS_TEST_TMPDIR/search-fails"
    run "$SWEEP"
    [ "$status" -ne 0 ]
    [[ "$output" == *"issue search failed"* ]]
}

@test "the --jq filter emits url and matching label names" {
    command -v jq >/dev/null || skip "jq not installed"
    # Apply the real filter (the arg after --jq) to sample search JSON.
    stub_command gh '
[[ "$1" == search ]] || exit 0
while [[ "$1" != --jq ]]; do shift; done
jq -r "$2" <<<"[{\"url\":\"https://x/1\",\"labels\":[{\"name\":\"bug\"},{\"name\":\"In Progress\"}]}]"
'
    run "$SWEEP"
    [ "$status" -eq 0 ]
    [ "$output" = "gh-sweep-in-progress: removed 'In Progress' label from https://x/1" ]
}
