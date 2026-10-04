#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    GH="$BIN_DIR/gh"
    OUT="$BATS_TEST_TMPDIR/gh-argv"
    export CLAUDECODE=1 OUT
    export CLAUDE_CODE_SESSION_ID=0f8e2a1c-test-session
    export TMPDIR="$BATS_TEST_TMPDIR/tmp"
    mkdir -p "$TMPDIR"
    # Fake real gh: log each arg, and the contents of any body file it points
    # at (the wrapper deletes its temp files once gh exits).
    stub_command gh '
for a in "$@"; do
    printf "ARG:%s\n" "$a"
    case $a in
        body=@*) f=${a#body=@} ;;
        --body-file=*) f=${a#--body-file=} ;;
        --input=*) f=${a#--input=} ;;
        *) f=$a ;;
    esac
    if [[ -f $f ]]; then printf "FILE:%s\n" "$(cat "$f")"; fi
done >"$OUT"'
    ANCHOR='[Claude Code](https://claude.com/claude-code)'
    GEN=$'hi\n\n---\n🤖 Generated with '"$ANCHOR · Opus 5.5"
    REV=$'lgtm\n\n---\n🤖 Review by '"$ANCHOR · Opus 5.5"
    BODY_FILE="$BATS_TEST_TMPDIR/body.md"
    printf '%s\n' "$GEN" >"$BODY_FILE"
}

# A bare `! cmd` never fails a bats test (set -e ignores negation).
refute() { ! "$@"; }
# Clear the previous call's log so a refusal is seen as nothing reaching gh.
gh_run() {
    rm -f "$OUT"
    run "$GH" "$@"
}
assert_passed() {
    [ "$status" -eq 0 ]
    [ -e "$OUT" ]
}
assert_refused() {
    [ "$status" -eq 1 ]
    [[ "$output" == *"refusing to post"* ]]
    [ ! -e "$OUT" ]
}

@test "a body ending with the trailer is passed through unchanged" {
    gh_run pr comment 1 --body "$GEN"
    assert_passed
    grep -qF "🤖 Generated with $ANCHOR · Opus 5.5" "$OUT"
}

@test "a body without the trailer is refused, naming the placeholder" {
    gh_run pr comment 1 --body hi
    assert_refused
    [[ "$output" == *"· <Model>"* ]]
    [[ "$output" == *"model you are running as"* ]]
}

@test "any model family and version is accepted" {
    for m in 'Sonnet 5' 'Haiku 4.5' 'Fable 5.1' 'Opus 4'; do
        gh_run pr comment 1 --body $'hi\n\n🤖 Generated with '"$ANCHOR · $m"
        assert_passed
    done
}

@test "a trailer without a recognised model is refused" {
    for m in '' ' · Opus' ' · GPT 5' ' · opus 5.5'; do
        gh_run pr comment 1 --body $'hi\n\n🤖 Generated with '"$ANCHOR$m"
        assert_refused
    done
}

@test "the trailer must be the last line; trailing whitespace is fine" {
    gh_run pr comment 1 --body "$GEN"$'\nPS'
    assert_refused
    gh_run pr comment 1 --body "$GEN"$'  \n\n'
    assert_passed
}

@test "the trailer verb must match the command" {
    gh_run pr comment 1 --body "$REV"
    assert_refused
    gh_run pr review 1 --comment --body "$GEN"
    assert_refused
    gh_run pr review 1 --approve --body "$REV"
    assert_passed
}

@test "body flag spellings are all checked" {
    for args in '--body=hi' '-b=hi' '-bhi' '-cbhi'; do
        gh_run pr review 1 "$args"
        assert_refused
    done
    gh_run issue create --title t "--body=$GEN"
    assert_passed
    gh_run pr edit 1 -b "$GEN"
    assert_passed
}

@test "issue/pr new, close and reopen are checked" {
    gh_run issue new --title t --body hi
    assert_refused
    gh_run issue close 1 --comment hi
    assert_refused
    gh_run pr reopen 1 -c hi
    assert_refused
    gh_run pr reopen 1 -c "$GEN"
    assert_passed
    gh_run issue close 1
    assert_passed
}

@test "a regular body file is checked and passed through as-is" {
    for args in "--body-file $BODY_FILE" "--body-file=$BODY_FILE" "-F $BODY_FILE" "-F$BODY_FILE"; do
        # shellcheck disable=SC2086
        gh_run issue comment 1 $args
        assert_passed
        grep -qF "$BODY_FILE" "$OUT"
        refute grep -q 'gh-body-' "$OUT"
    done
}

@test "a body file without the trailer is refused" {
    printf 'from a file\n' >"$BODY_FILE"
    gh_run pr create --title t --body-file "$BODY_FILE"
    assert_refused
}

@test "a stdin body is checked via a temp copy that is cleaned up" {
    gh_run pr comment 1 --body-file - <<<"$GEN"
    assert_passed
    refute grep -q '^ARG:-$' "$OUT"
    grep -qF 'FILE:hi' "$OUT"
    tmp=$(grep '^ARG:.*gh-body-' "$OUT" | sed 's/^ARG://')
    [ -n "$tmp" ]
    [ ! -e "$tmp" ]
    gh_run pr comment 1 --body-file - <<<'hi'
    assert_refused
}

@test "pipe body sources are checked via a temp copy" {
    gh_run pr comment 1 --body-file <(printf '%s\n' "$GEN")
    assert_passed
    grep -q '^ARG:.*gh-body-' "$OUT"
    gh_run pr comment 1 --body-file /dev/stdin <<<'hi'
    assert_refused
}

@test "missing and directory body files are refused" {
    gh_run pr comment 1 --body-file "$BATS_TEST_TMPDIR/missing.md"
    assert_refused
    gh_run pr comment 1 --body-file "$BATS_TEST_TMPDIR"
    assert_refused
}

@test "global and -R flags around the subcommand are skipped" {
    gh_run -R o/r issue comment 1 --body hi
    assert_refused
    gh_run --repo=o/r pr comment 1 --body hi
    assert_refused
    gh_run pr -R o/r comment 1 --body hi
    assert_refused
    gh_run --hostname example.com pr comment 1 --body hi
    assert_refused
    gh_run -R o/r pr comment 1 --body "$GEN"
    assert_passed
}

@test "commands without a body pass through" {
    gh_run pr create --fill
    assert_passed
    gh_run pr view 1 --comments
    assert_passed
    gh_run pr list
    assert_passed
}

@test "args after -- are positional, not body flags" {
    gh_run issue create --title t -- --body hi
    assert_passed
}

@test "CLAUDECODE unset passes everything through" {
    unset CLAUDECODE
    gh_run pr comment 1 --body 'hi https://claude.ai/code/session_01AbCdEfGhIjKlMnOpQrSt'
    assert_passed
}

@test "session links and ids are refused even with a trailer" {
    for leak in \
        'https://claude.ai/code/session_01AbCdEfGhIjKlMnOpQrSt' \
        'https://claude.ai/code/1b2c3d4e-0000-4000-8000-123456789abc' \
        'fixed in session_01ZyXwVuTsRqPoNmLkJi today' \
        'Session: 0F8E2A1C-TEST-SESSION'; do
        gh_run pr comment 1 --body "$leak"$'\n'"$GEN"
        assert_refused
    done
}

@test "ordinary session_ tokens and UUIDs are allowed" {
    gh_run pr comment 1 --body $'Set cookie session_8f7a9b3c2d1e4f5a\nrequest 66666666-7777-4888-9999-000000000000\n'"$GEN"
    assert_passed
}

@test "titles are checked for leaks but need no trailer" {
    gh_run pr create --title 'see session_01AbCdEfGhIjKlMnOpQrSt' --body "$GEN"
    assert_refused
    gh_run pr create -t 'plain title' --body "$GEN"
    assert_passed
}

@test "merge bodies and release notes need no trailer but are leak-checked" {
    gh_run pr merge 1 --squash --body 'squashed'
    assert_passed
    gh_run pr merge 1 --squash --body 'via session_01AbCdEfGhIjKlMnOpQrSt'
    assert_refused
    gh_run release create v1 --notes 'notes'
    assert_passed
    gh_run release edit v1 -n 'https://claude.ai/code/session_01AbCdEfGhIjKlMnOpQrSt'
    assert_refused
    gh_run pr merge 1 --subject 'session_01AbCdEfGhIjKlMnOpQrSt'
    assert_refused
    printf 'via session_01AbCdEfGhIjKlMnOpQrSt\n' >"$BODY_FILE"
    gh_run release create v1 --notes-file "$BODY_FILE"
    assert_refused
}

@test "pr revert needs the Generated with trailer" {
    gh_run pr revert 1 --body hi
    assert_refused
    gh_run pr revert 1 --body "$GEN"
    assert_passed
}

@test "api writes to comment endpoints need the trailer" {
    gh_run api -X POST repos/o/r/issues/1/comments -f body=hi
    assert_refused
    gh_run api --method=PATCH repos/o/r/issues/comments/9 --raw-field=body=hi
    assert_refused
    gh_run api -X PUT repos/o/r/issues/1/comments -f body=hi
    assert_refused
    gh_run api -X POST repos/o/r/issues/1/comments -f "body=$GEN"
    assert_passed
}

@test "api with fields and no -X defaults to POST" {
    gh_run api repos/o/r/issues/1/comments -f body=hi
    assert_refused
    gh_run api -f body=hi repos/o/r/issues/1/comments
    assert_refused
}

@test "api value-taking flags before the endpoint are skipped" {
    gh_run api -H 'Accept: application/vnd.github+json' --jq .id \
        repos/o/r/issues/1/comments -f body=hi
    assert_refused
}

@test "api reviews and replies endpoints need the Review by trailer" {
    gh_run api -X POST repos/o/r/pulls/1/reviews -f "body=$GEN"
    assert_refused
    gh_run api -X POST repos/o/r/pulls/1/comments/5/replies -f "body=$GEN"
    assert_refused
    gh_run api -X POST repos/o/r/pulls/1/comments/5/replies -f "body=$REV"
    assert_passed
}

@test "api -F body=@file reads the file; -f body=@file is a literal" {
    gh_run api -X POST repos/o/r/issues/1/comments -F "body=@$BODY_FILE"
    assert_passed
    grep -qF "ARG:body=@$BODY_FILE" "$OUT"
    gh_run api -X POST repos/o/r/issues/1/comments -f "body=@$BODY_FILE"
    assert_refused
}

@test "api GET and non-content endpoints pass through" {
    gh_run api repos/o/r/issues/1/comments
    assert_passed
    gh_run api -X GET repos/o/r/issues/comments -f since=2026-01-01
    assert_passed
    gh_run api -X POST repos/o/r/labels -f name=hi
    assert_passed
}

@test "api fields other than body are leak-checked" {
    gh_run api -X POST repos/o/r/issues -f title='session_01AbCdEfGhIjKlMnOpQrSt' -f "body=$GEN"
    assert_refused
    gh_run api -X POST repos/o/r/issues -f title=t -f "body=$GEN"
    assert_passed
}

@test "api --input JSON body is checked" {
    json="$BATS_TEST_TMPDIR/in.json"
    printf '{"body":"héllo","event":"COMMENT"}' >"$json"
    gh_run api repos/o/r/pulls/1/reviews --input "$json"
    assert_refused
    jq -cn --arg b "$REV" '{body: $b, event: "COMMENT"}' >"$json"
    gh_run api repos/o/r/pulls/1/reviews "--input=$json"
    assert_passed
    grep -qF "ARG:--input=$json" "$OUT"
}

@test "api --input - reads stdin via a temp copy" {
    jq -cn --arg b "$GEN" '{body: $b}' >"$BATS_TEST_TMPDIR/in.json"
    gh_run api repos/o/r/issues/1/comments --input - <"$BATS_TEST_TMPDIR/in.json"
    assert_passed
    refute grep -q '^ARG:-$' "$OUT"
    grep -q '^FILE:{"body"' "$OUT"
    gh_run api repos/o/r/issues/1/comments --input - <<<'{"body":"hi"}'
    assert_refused
}

@test "api --input without a body, or not JSON, passes through" {
    json="$BATS_TEST_TMPDIR/in.json"
    printf '{"title":"t"}' >"$json"
    gh_run api repos/o/r/issues --input "$json"
    assert_passed
    gh_run api repos/o/r/issues/1/comments --input - <<<'not json'
    assert_passed
    grep -q '^FILE:not json$' "$OUT"
}

@test "api --input leaks anywhere in the JSON are refused" {
    json="$BATS_TEST_TMPDIR/in.json"
    # Escaped so only the decoded-JSON walk, not the raw-text scan, sees it.
    jq -cn --arg b "$GEN" '{body: $b, comments: [{body: "x"}]}' |
        sed 's/"x"/"session\\u005f01AbCdEfGhIjKlMnOpQrSt"/' >"$json"
    grep -q 'u005f' "$json"
    gh_run api repos/o/r/pulls/1/reviews --input "$json"
    assert_refused
}

@test "graphql mutation bodies are checked via their variables" {
    q='mutation($b: String!) { addComment(input: {subjectId: "x", body: $b}) { clientMutationId } }'
    gh_run api graphql -f "query=$q" -f b=hi
    assert_refused
    gh_run api graphql -f "query=$q" -f "b=$GEN"
    assert_passed
}

@test "graphql review mutations need the Review by trailer" {
    q='mutation($b: String!) { addPullRequestReview(input: {pullRequestId: "x", body: $b}) { clientMutationId } }'
    gh_run api graphql -f "query=$q" -f "b=$GEN"
    assert_refused
    gh_run api graphql -f "query=$q" -f "b=$REV"
    assert_passed
}

@test "graphql inline bodies and missing variables are refused" {
    gh_run api graphql -f 'query=mutation { addComment(input: {subjectId: "x", body: "hi"}) { clientMutationId } }'
    assert_refused
    gh_run api graphql -f 'query=mutation($b: String!) { addComment(input: {subjectId: "x", body: $b}) { clientMutationId } }'
    assert_refused
}

@test "graphql input variables have their body checked" {
    q='mutation($in: AddCommentInput!) { addComment(input: $in) { clientMutationId } }'
    gh_run api graphql -f "query=$q" -f 'in[subjectId]=x' -f 'in[body]=hi'
    assert_refused
    gh_run api graphql -f "query=$q" -f 'in[subjectId]=x' -f "in[body]=$GEN"
    assert_passed
}

@test "graphql bodies inside lists and plain queries need no trailer" {
    q='mutation($b: String!, $t: String!) { addPullRequestReview(input: {pullRequestId: "x", body: $b, threads: [{path: "f", body: $t}]}) { clientMutationId } }'
    gh_run api graphql -f "query=$q" -f "b=$REV" -f t=nit
    assert_passed
    gh_run api graphql -f 'query={ viewer { login } }'
    assert_passed
}

@test "exit status of real gh is propagated after a temp-file copy" {
    stub_command gh 'exit 3'
    gh_run pr comment 1 --body-file - <<<"$GEN"
    [ "$status" -eq 3 ]
    stub_command gh 'kill -TERM $$'
    gh_run pr comment 1 --body-file - <<<"$GEN"
    [ "$status" -eq 143 ]
    [ -z "$(ls -A "$TMPDIR")" ]
}

@test "temp bodies are removed when the post is refused" {
    # stdin --input is copied to a temp file before the bad -F file blocks
    run bash -c "printf '{}' | '$GH' api repos/o/r/issues/1/comments --input - -F body=@'$BATS_TEST_TMPDIR/missing'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"is unreadable"* ]]
    [ -z "$(ls -A "$TMPDIR")" ]
}

@test "graphql via --input reads query and variables from the JSON" {
    json="$BATS_TEST_TMPDIR/in.json"
    q='mutation($b: String!) { addComment(input: {subjectId: "x", body: $b}) { clientMutationId } }'
    jq -cn --arg q "$q" '{query: $q, variables: {b: "hi"}}' >"$json"
    gh_run api graphql --input "$json"
    assert_refused
    jq -cn --arg q "$q" --arg b "$GEN" '{query: $q, variables: {b: $b}}' >"$json"
    gh_run api graphql --input "$json"
    assert_passed
}

@test "graphql commas and comments cannot hide an inline body" {
    gh_run api graphql -f 'query=mutation { addComment(input: {subjectId: "x",body: "hi"}) { clientMutationId } }'
    assert_refused
    gh_run api graphql -f $'query=mutation { addComment(input: {subjectId: "x" # ]\n body: "hi"}) { clientMutationId } }'
    assert_refused
}

@test "graphql review thread replies need the Review by trailer" {
    q='mutation($b: String!) { addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: "x", body: $b}) { clientMutationId } }'
    gh_run api graphql -f "query=$q" -f "b=$GEN"
    assert_refused
    gh_run api graphql -f "query=$q" -f "b=$REV"
    assert_passed
}
