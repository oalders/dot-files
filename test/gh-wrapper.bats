#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    GH="$BIN_DIR/gh"
    OUT="$BATS_TEST_TMPDIR/gh-argv"
    export CLAUDECODE=1 OUT
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
    BODY_FILE="$BATS_TEST_TMPDIR/body.md"
    printf 'from a file\n' >"$BODY_FILE"
    # The wrapper reads the running model from this session's transcript.
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude"
    export CLAUDE_CODE_SESSION_ID=0f8e2a1c-test-session
    TRANSCRIPT_DIR="$CLAUDE_CONFIG_DIR/projects/-proj"
    mkdir -p "$TRANSCRIPT_DIR"
    write_transcript "$TRANSCRIPT_DIR/$CLAUDE_CODE_SESSION_ID.jsonl" claude-opus-5-5
}

write_transcript() {
    printf '{"type":"assistant","message":{"model":"claude-sonnet-4-6"}}\n' >"$1"
    printf '{"type":"assistant","message":{"model":"%s"}}\n' "$2" >>"$1"
    printf '{"type":"user","message":{"content":[{"input":{"model":"sonnet"}}]}}\n' >>"$1"
}

assert_generated() { grep -q 'Generated with \[Claude Code\]' "$OUT"; }
assert_review() { grep -q 'Review by \[Claude Code\]' "$OUT"; }
assert_no_footer() { ! grep -q '\[Claude Code\]' "$OUT"; }
# A bare `! cmd` never fails a bats test (set -e ignores negation).
refute() { ! "$@"; }
footer_count() { grep -c 'Generated with \[Claude Code\]' "$OUT"; }

@test "pr comment --body gets footer" {
    run "$GH" pr comment 1 --body hi
    [ "$status" -eq 0 ]
    grep -q '^ARG:hi$' "$OUT"
    assert_generated
}

@test "issue create --body= gets footer" {
    run "$GH" issue create --title t --body=hi
    [ "$status" -eq 0 ]
    grep -q '^ARG:--body=hi$' "$OUT"
    assert_generated
}

@test "pr edit -b gets footer" {
    run "$GH" pr edit 1 -b hi
    [ "$status" -eq 0 ]
    assert_generated
}

@test "--body-file is rewritten to a footered temp file" {
    run "$GH" pr create --title t --body-file "$BODY_FILE"
    [ "$status" -eq 0 ]
    grep -q '^FILE:from a file$' "$OUT"
    assert_generated
    refute grep -q "^ARG:$BODY_FILE$" "$OUT"
    # Original file untouched.
    refute grep -q 'Claude Code' "$BODY_FILE"
}

@test "--body-file= and -F forms get footer" {
    run "$GH" issue comment 1 "--body-file=$BODY_FILE"
    [ "$status" -eq 0 ]
    assert_generated
    run "$GH" issue comment 1 -F "$BODY_FILE"
    [ "$status" -eq 0 ]
    assert_generated
}

@test "temp body file is cleaned up" {
    run "$GH" pr comment 1 --body-file "$BODY_FILE"
    [ "$status" -eq 0 ]
    tmp=$(grep '^ARG:.*gh-body-' "$OUT" | sed 's/^ARG://')
    [ -n "$tmp" ]
    [ ! -e "$tmp" ]
}

@test "body already carrying the footer is not doubled" {
    body=$'hi\n\n---\n🤖 Generated with [Claude Code](https://claude.com/claude-code)'
    run "$GH" pr comment 1 --body "$body"
    [ "$status" -eq 0 ]
    [ "$(footer_count)" -eq 1 ]
}

@test "--body-file - (stdin) is blocked" {
    run "$GH" pr comment 1 --body-file -
    [ "$status" -eq 1 ]
    [[ "$output" == *"refusing to post"* ]]
    [ ! -e "$OUT" ]
}

@test "unreadable body file is blocked" {
    run "$GH" pr comment 1 --body-file "$BATS_TEST_TMPDIR/missing.md"
    [ "$status" -eq 1 ]
    [ ! -e "$OUT" ]
}

@test "global flags before the subcommand are skipped" {
    run "$GH" -R o/r issue comment 1 --body hi
    [ "$status" -eq 0 ]
    assert_generated
    run "$GH" --repo=o/r pr comment 1 --body hi
    [ "$status" -eq 0 ]
    assert_generated
}

@test "no body flag passes through (editor / --fill)" {
    run "$GH" pr create --fill
    [ "$status" -eq 0 ]
    assert_no_footer
}

@test "non-mutating subcommands pass through" {
    run "$GH" pr view 1 --comments
    [ "$status" -eq 0 ]
    assert_no_footer
    run "$GH" pr list
    [ "$status" -eq 0 ]
    assert_no_footer
}

@test "CLAUDECODE unset passes through untouched" {
    unset CLAUDECODE
    run "$GH" pr comment 1 --body hi
    [ "$status" -eq 0 ]
    assert_no_footer
}

@test "api POST -f body= on comments gets footer" {
    run "$GH" api -X POST repos/o/r/issues/1/comments -f body=hi
    [ "$status" -eq 0 ]
    grep -q '^ARG:body=hi$' "$OUT"
    assert_generated
}

@test "api PATCH --raw-field= glued form gets footer" {
    run "$GH" api --method=PATCH repos/o/r/issues/comments/9 --raw-field=body=hi
    [ "$status" -eq 0 ]
    grep -q '^ARG:--raw-field=body=hi$' "$OUT"
    assert_generated
}

@test "api -F body=@file gets footer via temp file" {
    run "$GH" api -X POST repos/o/r/issues/1/comments -F "body=@$BODY_FILE"
    [ "$status" -eq 0 ]
    grep -q '^FILE:from a file$' "$OUT"
    assert_generated
}

@test "api -f body=@file is a literal, not a file" {
    run "$GH" api -X POST repos/o/r/issues/1/comments -f "body=@$BODY_FILE"
    [ "$status" -eq 0 ]
    refute grep -q '^FILE:' "$OUT"
    assert_generated
}

@test "api reviews and replies endpoints get the review footer" {
    run "$GH" api -X POST repos/o/r/pulls/1/reviews -f body=lgtm
    [ "$status" -eq 0 ]
    assert_review
    run "$GH" api -X POST repos/o/r/pulls/1/comments/5/replies -f body=ok
    [ "$status" -eq 0 ]
    assert_review
}

@test "api GET and non-content endpoints pass through" {
    run "$GH" api repos/o/r/issues/1/comments
    [ "$status" -eq 0 ]
    assert_no_footer
    run "$GH" api -X POST repos/o/r/labels -f body=hi
    [ "$status" -eq 0 ]
    assert_no_footer
}

@test "api fields other than body are untouched" {
    run "$GH" api -X POST repos/o/r/issues -f title=t -f body=hi
    [ "$status" -eq 0 ]
    grep -q '^ARG:title=t$' "$OUT"
    assert_generated
}

@test "glued -bTEXT and -FFILE forms get footer" {
    run "$GH" pr comment 1 -bhi
    [ "$status" -eq 0 ]
    grep -q '^ARG:-bhi$' "$OUT"
    assert_generated
    run "$GH" issue comment 1 "-F$BODY_FILE"
    [ "$status" -eq 0 ]
    grep -q '^ARG:-F.*gh-body-' "$OUT"
}

@test "api with fields and no -X defaults to POST" {
    run "$GH" api repos/o/r/issues/1/comments -f body=hi
    [ "$status" -eq 0 ]
    assert_generated
}

@test "api value-taking flags before the endpoint are skipped" {
    run "$GH" api -H 'Accept: application/vnd.github+json' --jq .id \
        repos/o/r/issues/1/comments -f body=hi
    [ "$status" -eq 0 ]
    assert_generated
    run "$GH" api -f body=hi repos/o/r/issues/1/comments
    [ "$status" -eq 0 ]
    assert_generated
}

@test "api GET with explicit -X and fields passes through" {
    run "$GH" api -X GET repos/o/r/issues/comments -f since=2026-01-01
    [ "$status" -eq 0 ]
    assert_no_footer
}

@test "exit status of real gh is propagated after temp-file rewrite" {
    stub_command gh 'exit 3'
    run "$GH" pr comment 1 --body-file "$BODY_FILE"
    [ "$status" -eq 3 ]
    stub_command gh 'kill -TERM $$'
    run "$GH" pr comment 1 --body-file "$BODY_FILE"
    [ "$status" -eq 143 ]
}

@test "args after -- are positional, not body flags" {
    run "$GH" issue create --title t -- --body hi
    [ "$status" -eq 0 ]
    grep -q '^ARG:hi$' "$OUT"
    assert_no_footer
}

@test "api --input JSON body gets footer, defaulting to POST" {
    json="$BATS_TEST_TMPDIR/in.json"
    printf '{"body":"héllo","event":"COMMENT"}' >"$json"
    run "$GH" api repos/o/r/pulls/1/reviews --input "$json"
    [ "$status" -eq 0 ]
    grep -q '^FILE:.*héllo' "$OUT"
    grep -q '"event":"COMMENT"' "$OUT"
    assert_review
    refute grep -q "^ARG:$json$" "$OUT"
    refute grep -q 'Claude Code' "$json"
}

@test "api --input= glued form gets footer" {
    json="$BATS_TEST_TMPDIR/in.json"
    printf '{"body":"hi"}' >"$json"
    run "$GH" api -X POST repos/o/r/issues/1/comments "--input=$json"
    [ "$status" -eq 0 ]
    grep -q '^ARG:--input=.*gh-body-' "$OUT"
    assert_generated
}

@test "api --input - reads stdin and footers it" {
    run "$GH" api repos/o/r/issues/1/comments --input - <<<'{"body":"hi"}'
    [ "$status" -eq 0 ]
    refute grep -q '^ARG:-$' "$OUT"
    grep -q '^FILE:{"body":"hi' "$OUT"
    assert_generated
}

@test "api --input without a body key passes the file through" {
    json="$BATS_TEST_TMPDIR/in.json"
    printf '{"title":"t"}' >"$json"
    run "$GH" api repos/o/r/issues --input "$json"
    [ "$status" -eq 0 ]
    grep -q "^ARG:$json$" "$OUT"
    assert_no_footer
}

@test "api --input - with non-JSON stdin is forwarded unchanged" {
    run "$GH" api repos/o/r/issues/1/comments --input - <<<'not json'
    [ "$status" -eq 0 ]
    grep -q '^FILE:not json$' "$OUT"
    assert_no_footer
}

@test "api --input with a model-less footer gets exactly one model footer" {
    json="$BATS_TEST_TMPDIR/in.json"
    printf '{"body":"hi\\n\\n---\\nGenerated with [Claude Code](https://claude.com/claude-code)"}' >"$json"
    run "$GH" api repos/o/r/issues/1/comments --input "$json"
    [ "$status" -eq 0 ]
    [ "$(grep -o 'Generated with' "$OUT" | wc -l)" -eq 1 ]
    grep -q 'claude-code) · Opus 5.5' "$OUT"
}

@test "footer names the running model" {
    run "$GH" pr comment 1 --body hi
    [ "$status" -eq 0 ]
    grep -q '^🤖 Generated with \[Claude Code\](https://claude.com/claude-code) · Opus 5.5$' "$OUT"
}

@test "newest transcript wins, so a subagent is attributed to its own model" {
    sub="$TRANSCRIPT_DIR/$CLAUDE_CODE_SESSION_ID/subagents"
    mkdir -p "$sub"
    write_transcript "$sub/agent-x.jsonl" claude-sonnet-5
    touch -d '1 minute ago' "$TRANSCRIPT_DIR/$CLAUDE_CODE_SESSION_ID.jsonl"
    run "$GH" pr comment 1 --body hi
    [ "$status" -eq 0 ]
    grep -q '· Sonnet 5$' "$OUT"
}

@test "dated and bracketed model ids are shortened" {
    write_transcript "$TRANSCRIPT_DIR/$CLAUDE_CODE_SESSION_ID.jsonl" claude-haiku-4-5-20251001
    run "$GH" pr comment 1 --body hi
    grep -q '· Haiku 4.5$' "$OUT"
    write_transcript "$TRANSCRIPT_DIR/$CLAUDE_CODE_SESSION_ID.jsonl" 'claude-opus-4-8[1m]'
    run "$GH" pr comment 1 --body hi
    grep -q '· Opus 4.8$' "$OUT"
}

@test "unresolvable model blocks the post" {
    rm "$TRANSCRIPT_DIR/$CLAUDE_CODE_SESSION_ID.jsonl"
    run "$GH" pr comment 1 --body hi
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot determine the running Claude model"* ]]
    [ ! -e "$OUT" ]
}

@test "a footer naming the wrong model, or none, is replaced" {
    body=$'hi\n\n---\n🤖 Generated with [Claude Code](https://claude.com/claude-code) · Opus 4.1'
    run "$GH" pr comment 1 --body "$body"
    [ "$(footer_count)" -eq 1 ]
    refute grep -q 'Opus 4.1' "$OUT"
    grep -q '· Opus 5.5$' "$OUT"
}

@test "session ids and links are stripped" {
    body=$'hi\nhttps://claude.ai/code/session_01AbCdEfGhIjKlMnOpQrSt\nSession: 0F8E2A1C-TEST-SESSION\nsee https://claude.ai/code/1b2c3d4e-0000-4000-8000-123456789abc\nfixed in session_01ZyXwVuTsRqPoNmLkJi today\nkeep this line about session ids'
    run "$GH" pr comment 1 --body "$body"
    [ "$status" -eq 0 ]
    refute grep -qi 'session_01\|test-session\|claude.ai/code\|1b2c3d4e' "$OUT"
    refute grep -qi '^Session' "$OUT"
    grep -q '^fixed in  today$' "$OUT"
    grep -q 'keep this line about session ids' "$OUT"
    grep -q '^ARG:hi$' "$OUT"
}

@test "ordinary session_ tokens in content are kept" {
    run "$GH" pr comment 1 --body 'Set cookie session_8f7a9b3c2d1e4f5a and reload'
    [ "$status" -eq 0 ]
    grep -q '^ARG:Set cookie session_8f7a9b3c2d1e4f5a and reload$' "$OUT"
}

@test "a model named in a tool input is not mistaken for the running one" {
    t="$TRANSCRIPT_DIR/$CLAUDE_CODE_SESSION_ID.jsonl"
    write_transcript "$t" claude-opus-5-5
    printf '{"type":"assistant","message":{"model":"claude-opus-5-5","content":[{"type":"tool_use","input":{"model":"claude-haiku-4-5"}}]}}\n' >>"$t"
    printf '{"type":"user","message":{"content":[{"type":"tool_result","content":"{\\"model\\":\\"claude-haiku-4-5\\"}"}]}}\n' >>"$t"
    run "$GH" pr comment 1 --body hi
    grep -q '· Opus 5.5$' "$OUT"
}

@test "a config dir with a space in it still resolves the model" {
    new="$BATS_TEST_TMPDIR/my claude"
    mv "$CLAUDE_CONFIG_DIR" "$new"
    export CLAUDE_CONFIG_DIR="$new"
    run "$GH" pr comment 1 --body hi
    [ "$status" -eq 0 ]
    grep -q '· Opus 5.5$' "$OUT"
}

@test "an existing Review by footer keeps its kind" {
    body=$'lgtm\n\n---\n🤖 Review by [Claude Code](https://claude.com/claude-code)'
    run "$GH" pr comment 1 --body "$body"
    grep -q '^🤖 Review by .* · Opus 5.5$' "$OUT"
    refute grep -q 'Generated with' "$OUT"
}

@test "an already-correct body file is passed through as-is" {
    printf 'hi\n\n---\n🤖 Generated with [Claude Code](https://claude.com/claude-code) · Opus 5.5\n' >"$BODY_FILE"
    run "$GH" pr comment 1 --body-file "$BODY_FILE"
    [ "$status" -eq 0 ]
    grep -q "^ARG:$BODY_FILE$" "$OUT"
}

@test "a session link inside a markdown link keeps the link text" {
    run "$GH" pr comment 1 --body 'See [the session log](https://claude.ai/code/session_01AbCdEfGhIjKlMnOpQrSt) for details.'
    [ "$status" -eq 0 ]
    grep -q '^ARG:See the session log for details.$' "$OUT"
}

@test "a bare session UUID is stripped, other UUIDs are kept" {
    run "$GH" pr comment 1 --body $'from session 11111111-2222-3333-4444-555555555555 today\nrequest 66666666-7777-4888-9999-000000000000 failed'
    [ "$status" -eq 0 ]
    refute grep -q '11111111-2222' "$OUT"
    grep -q '^ARG:from session  today$' "$OUT"
    grep -q 'request 66666666-7777-4888-9999-000000000000 failed' "$OUT"
}

@test "a malformed model string blocks rather than being posted" {
    printf '{"type":"assistant","message":{"model":"claude-x <img src=y>"}}\n' \
        >"$TRANSCRIPT_DIR/$CLAUDE_CODE_SESSION_ID.jsonl"
    run "$GH" pr comment 1 --body hi
    [ "$status" -eq 1 ]
    [ ! -e "$OUT" ]
}

@test "glob characters in the config dir are taken literally" {
    new="$BATS_TEST_TMPDIR/c{la,x}ude*"
    mv "$CLAUDE_CONFIG_DIR" "$new"
    mkdir -p "$BATS_TEST_TMPDIR/cxude/projects/p"
    write_transcript "$BATS_TEST_TMPDIR/cxude/projects/p/$CLAUDE_CODE_SESSION_ID.jsonl" claude-haiku-4-5
    export CLAUDE_CONFIG_DIR="$new"
    run "$GH" pr comment 1 --body hi
    [ "$status" -eq 0 ]
    grep -q '· Opus 5.5$' "$OUT"
}

@test "temp bodies are removed when the post is refused" {
    export TMPDIR="$BATS_TEST_TMPDIR/tmp"
    mkdir -p "$TMPDIR"
    # stdin --input is copied to a temp file before the bad -F file blocks
    run bash -c "printf '{}' | '$GH' api repos/o/r/issues/1/comments --input - -F body=@'$BATS_TEST_TMPDIR/missing'"
    [ "$status" -eq 1 ]
    [ -z "$(ls -A "$TMPDIR")" ]
}

@test "session stripping spares neighbours: punctuation, obsession, titles" {
    run "$GH" pr comment 1 --body $'See https://app.claude.ai/code/session_01AbCdEfGhIjKlMnOpQrSt, then go.\nan obsession with order 12345678-1234-1234-1234-123456789012\n[11111111-2222-3333-4444-555555555555](https://claude.ai/code/session_x "t") here\n[foo](https://claude.ai/code/session_x \'t\') via https://my.app.claude.ai/code/session_y now'
    [ "$status" -eq 0 ]
    grep -q '^ARG:See , then go.$' "$OUT"
    grep -q '^foo via  now$' "$OUT"
    grep -q 'obsession with order 12345678-1234-1234-1234-123456789012$' "$OUT"
    refute grep -q 'claude.ai\|11111111' "$OUT"
}
