#!/usr/bin/env bats

load 'helpers.bash'

# The gh stub logs each call's args (one per line, blank-line separated) and
# answers `gh search` with $BATS_TEST_TMPDIR/found, i.e. post---jq output,
# after printing SEARCH-RAN to stderr.
# `gh api graphql` appends its query to graphql.log and answers with
# $BATS_TEST_TMPDIR/response if present, else success for every alias except
# those listed in null-aliases.
setup() {
    setup_sandbox
    SWEEP="$BIN_DIR/gh-sweep-in-progress"
    stub_command gh '
printf "%s\n" "$@" "" >>"$BATS_TEST_TMPDIR/gh.log"
case "$1" in
    search)
        echo SEARCH-RAN >&2
        [[ -e "$BATS_TEST_TMPDIR/search-fails" ]] && exit 1
        cat "$BATS_TEST_TMPDIR/found" 2>/dev/null
        ;;
    api)
        query=${4#query=}
        printf "%s\n" "$query" >>"$BATS_TEST_TMPDIR/graphql.log"
        if [[ -e "$BATS_TEST_TMPDIR/response" ]]; then
            cat "$BATS_TEST_TMPDIR/response"
            exit 1
        fi
        rc=0 sep=
        printf "{\"data\":{"
        for m in $(grep -oE "m[0-9]+:" <<<"$query" | tr -d :); do
            if grep -qx "$m" "$BATS_TEST_TMPDIR/null-aliases" 2>/dev/null; then
                printf "%s\"%s\":null" "$sep" "$m"
                rc=1
            else
                printf "%s\"%s\":{\"clientMutationId\":null}" "$sep" "$m"
            fi
            sep=,
        done
        printf "}}\n"
        exit "$rc"
        ;;
esac
exit 0
'
    stub_command sleep 'echo "$*" >>"$BATS_TEST_TMPDIR/sleep.log"'
}

# found_issues N: N found issues, I_<n> at https://x/<n> with label LA_<n>.
found_issues() {
    for ((n = 1; n <= $1; n++)); do
        printf 'I_%s\thttps://x/%s\tLA_%s\tin progress\n' "$n" "$n" "$n"
    done >"$BATS_TEST_TMPDIR/found"
}

@test "removes the exact-case label from each found issue in one request" {
    command -v jq >/dev/null || skip "jq not installed"
    printf 'I_1\thttps://x/1\tLA_a\tin progress\nI_2\thttps://x/2\tLA_b\tIn Progress\n' >"$BATS_TEST_TMPDIR/found"
    run "$SWEEP"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '%s\n' \
        SEARCH-RAN \
        "gh-sweep-in-progress: removed 'in progress' label from https://x/1" \
        "gh-sweep-in-progress: removed 'In Progress' label from https://x/2")" ]
    run cat "$BATS_TEST_TMPDIR/graphql.log"
    [ "${#lines[@]}" -eq 1 ]
    [[ "$output" == *'m0: removeLabelsFromLabelable(input: {labelableId: "I_1", labelIds: ["LA_a"]})'* ]]
    [[ "$output" == *'m1: removeLabelsFromLabelable(input: {labelableId: "I_2", labelIds: ["LA_b"]})'* ]]
    [ ! -e "$BATS_TEST_TMPDIR/sleep.log" ]
}

@test "more than 50 issues are sent in two requests with one pause" {
    command -v jq >/dev/null || skip "jq not installed"
    found_issues 51
    run "$SWEEP"
    [ "$status" -eq 0 ]
    [ "$(grep -c removed <<<"$output")" -eq 51 ]
    [[ "$output" == *"removed 'in progress' label from https://x/51"* ]]
    run cat "$BATS_TEST_TMPDIR/graphql.log"
    [ "${#lines[@]}" -eq 2 ]
    [ "$(grep -o removeLabelsFromLabelable <<<"${lines[0]}" | wc -l)" -eq 50 ]
    [[ "${lines[1]}" == *'labelableId: "I_51"'* ]]
    [[ "${lines[1]}" != *'"I_1"'* ]]
    run cat "$BATS_TEST_TMPDIR/sleep.log"
    [ "$output" = 2 ]
}

@test "a null mutation warns, the rest are removed, and exits 1" {
    command -v jq >/dev/null || skip "jq not installed"
    found_issues 3
    echo m1 >"$BATS_TEST_TMPDIR/null-aliases"
    run "$SWEEP"
    [ "$status" -eq 1 ]
    [[ "$output" == *"warning: could not remove 'in progress' label from https://x/2"* ]]
    [[ "$output" == *"removed 'in progress' label from https://x/1"* ]]
    [[ "$output" == *"removed 'in progress' label from https://x/3"* ]]
    [[ "$output" != *"removed 'in progress' label from https://x/2"* ]]
}

@test "a request with no data warns for its batch and skips the rest" {
    command -v jq >/dev/null || skip "jq not installed"
    found_issues 51
    echo '{"message":"You have exceeded a secondary rate limit"}' >"$BATS_TEST_TMPDIR/response"
    run "$SWEEP"
    [ "$status" -eq 1 ]
    [ "$(grep -c 'warning: could not remove' <<<"$output")" -eq 50 ]
    [[ "$output" == *"skipped the remaining 1 issue(s)"* ]]
    [[ "$output" != *removed* ]]
    run cat "$BATS_TEST_TMPDIR/graphql.log"
    [ "${#lines[@]}" -eq 1 ]
    [ ! -e "$BATS_TEST_TMPDIR/sleep.log" ]
}

@test "a later batch with every alias null stops after the earlier success" {
    command -v jq >/dev/null || skip "jq not installed"
    found_issues 101
    seq 50 99 | sed 's/^/m/' >"$BATS_TEST_TMPDIR/null-aliases"
    run "$SWEEP"
    [ "$status" -eq 1 ]
    [ "$(grep -c removed <<<"$output")" -eq 50 ]
    [[ "$output" == *"removed 'in progress' label from https://x/50"* ]]
    [ "$(grep -c 'warning: could not remove' <<<"$output")" -eq 50 ]
    [[ "$output" == *"warning: could not remove 'in progress' label from https://x/100"* ]]
    [[ "$output" == *"skipped the remaining 1 issue(s)"* ]]
    run cat "$BATS_TEST_TMPDIR/graphql.log"
    [ "${#lines[@]}" -eq 2 ]
}

@test "an id that is unsafe to interpolate warns and is not sent" {
    command -v jq >/dev/null || skip "jq not installed"
    printf 'I_1"}\thttps://x/1\tLA_a\tin progress\nI_2\thttps://x/2\tLA_b\tin progress\nI_3\thttps://x/3\tLA_c"}\tin progress\n' >"$BATS_TEST_TMPDIR/found"
    run "$SWEEP"
    [ "$status" -eq 1 ]
    [[ "$output" == *"warning: could not remove 'in progress' label from https://x/1"* ]]
    [[ "$output" == *"warning: could not remove 'in progress' label from https://x/3"* ]]
    [[ "$output" == *"removed 'in progress' label from https://x/2"* ]]
    run cat "$BATS_TEST_TMPDIR/graphql.log"
    [[ "$output" != *I_1* ]]
    [[ "$output" != *I_3* ]]
    [[ "$output" == *'"I_2"'* ]]
}

@test "searches closed, unarchived issues for the default owner" {
    run "$SWEEP"
    [ "$status" -eq 0 ]
    run grep -A1 -x -- --owner "$BATS_TEST_TMPDIR/gh.log"
    [ "$output" = "$(printf -- '--owner\noalders')" ]
    grep -qx -- --archived=false "$BATS_TEST_TMPDIR/gh.log"
    grep -A1 -x -- --state "$BATS_TEST_TMPDIR/gh.log" | grep -qx closed
    grep -A1 -x -- --label "$BATS_TEST_TMPDIR/gh.log" | grep -qx 'in progress'
    grep -A1 -x -- --limit "$BATS_TEST_TMPDIR/gh.log" | grep -qx 1000
    grep -A1 -x -- --json "$BATS_TEST_TMPDIR/gh.log" | grep -qx id,url,labels
    [ ! -e "$BATS_TEST_TMPDIR/graphql.log" ]
}

@test "--max is passed to the search as --limit" {
    run "$SWEEP" --max 50
    [ "$status" -eq 0 ]
    grep -A1 -x -- --limit "$BATS_TEST_TMPDIR/gh.log" | grep -qx 50
    rm "$BATS_TEST_TMPDIR/gh.log"
    run "$SWEEP" --max=5000
    [ "$status" -eq 0 ]
    grep -A1 -x -- --limit "$BATS_TEST_TMPDIR/gh.log" | grep -qx 1000
}

@test "--max rejects zero and non-numbers" {
    for bad in 0 abc -1 ''; do
        run "$SWEEP" --max "$bad"
        [ "$status" -eq 2 ]
        [[ "$output" == *"--max needs a positive integer"* ]]
    done
    run "$SWEEP" --max
    [ "$status" -eq 2 ]
    [ ! -e "$BATS_TEST_TMPDIR/gh.log" ]
}

@test "-v reports zero results for the default owner" {
    run "$SWEEP" -v
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '%s\n' \
        "gh-sweep-in-progress: searching closed issues labelled 'in progress' for oalders..." \
        SEARCH-RAN \
        "gh-sweep-in-progress: found 0 closed issue(s) labelled 'in progress' for oalders")" ]
}

@test "--verbose counts found issues and still removes labels" {
    command -v jq >/dev/null || skip "jq not installed"
    found_issues 2
    run "$SWEEP" --verbose --owner a --owner b
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "gh-sweep-in-progress: searching closed issues labelled 'in progress' for a, b..." ]
    [ "${lines[2]}" = "gh-sweep-in-progress: found 2 closed issue(s) labelled 'in progress' for a, b" ]
    [[ "$output" == *"removed 'in progress' label from https://x/1"* ]]
    [[ "$output" == *"removed 'in progress' label from https://x/2"* ]]
    [[ "$output" != *"reached --max"* ]]
}

@test "-v says when the found count reaches --max" {
    command -v jq >/dev/null || skip "jq not installed"
    found_issues 2
    run "$SWEEP" -v --max 2
    [ "$status" -eq 0 ]
    [ "${lines[2]}" = "gh-sweep-in-progress: found 2 closed issue(s) labelled 'in progress' for oalders" ]
    [ "${lines[3]}" = "gh-sweep-in-progress: reached --max 2; more may remain, re-run to continue" ]
}

@test "each --owner is passed as its own flag" {
    run "$SWEEP" --owner a --owner=b
    [ "$status" -eq 0 ]
    run grep -A1 -x -- --owner "$BATS_TEST_TMPDIR/gh.log"
    [ "$output" = "$(printf -- '--owner\na\n--owner\nb')" ]
}

@test "a failed search exits 1" {
    : >"$BATS_TEST_TMPDIR/search-fails"
    run "$SWEEP"
    [ "$status" -eq 1 ]
    [[ "$output" == *"issue search failed"* ]]
}

@test "the --jq filter emits issue id, url, label id and matching label names" {
    command -v jq >/dev/null || skip "jq not installed"
    # Apply the real filter (the arg after --jq) to sample search JSON.
    stub_command gh '
if [[ "$1" == api ]]; then
    printf "%s\n" "${4#query=}" >"$BATS_TEST_TMPDIR/graphql.log"
    echo "{\"data\":{\"m0\":{}}}"
    exit 0
fi
while [[ "$1" != --jq ]]; do shift; done
jq -r "$2" <<<"[{\"id\":\"I_1\",\"url\":\"https://x/1\",\"labels\":[{\"id\":\"LA_b\",\"name\":\"bug\"},{\"id\":\"LA_p\",\"name\":\"In Progress\"}]}]"
'
    run "$SWEEP"
    [ "$status" -eq 0 ]
    [ "$output" = "gh-sweep-in-progress: removed 'In Progress' label from https://x/1" ]
    grep -qF 'labelableId: "I_1", labelIds: ["LA_p"]' "$BATS_TEST_TMPDIR/graphql.log"
}
