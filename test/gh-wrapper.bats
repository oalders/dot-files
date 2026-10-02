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
        *) f=$a ;;
    esac
    if [[ -f $f ]]; then printf "FILE:%s\n" "$(cat "$f")"; fi
done >"$OUT"'
    BODY_FILE="$BATS_TEST_TMPDIR/body.md"
    printf 'from a file\n' >"$BODY_FILE"
}

assert_generated() { grep -q 'Generated with \[Claude Code\]' "$OUT"; }
assert_review() { grep -q 'Review by \[Claude Code\]' "$OUT"; }
assert_no_footer() { ! grep -q '\[Claude Code\]' "$OUT"; }
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
    ! grep -q "^ARG:$BODY_FILE$" "$OUT"
    # Original file untouched.
    ! grep -q 'Claude Code' "$BODY_FILE"
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
    ! grep -q '^FILE:' "$OUT"
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
