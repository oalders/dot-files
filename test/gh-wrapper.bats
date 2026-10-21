#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    GH="$BIN_DIR/gh"
    OUT="$BATS_TEST_TMPDIR/gh-argv"
    # `owner/repo visibility` lines the stub answers `gh repo view` from.
    VIS="$BATS_TEST_TMPDIR/visibility"
    : >"$VIS"
    export CLAUDECODE=1 OUT VIS
    export CLAUDE_CODE_SESSION_ID=0f8e2a1c-test-session
    export TMPDIR="$BATS_TEST_TMPDIR/tmp"
    export HOME="$BATS_TEST_TMPDIR/home"
    export GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR"
    unset NN_SESSION_DIR GH_REPO
    mkdir -p "$TMPDIR" "$HOME/.config/gh" "$BATS_TEST_TMPDIR/work"
    cd "$BATS_TEST_TMPDIR/work"
    # Fake real gh. Visibility lookups are answered from $VIS and recorded in
    # $OUT.lookups, never $OUT; anything else logs each arg, and the contents
    # of any body file it points at (the wrapper deletes its temp files once
    # gh exits). `gh auth` also records its stdin.
    stub_command gh '
if [[ $1 == repo && $2 == view && $4 == --json ]]; then
    echo "$3" >>"$OUT.lookups"
    while read -r k v; do
        if [[ $k == "$3" ]]; then echo "${v^^}"; exit 0; fi
    done <"$VIS"
    exit 1
fi
[[ $1 == auth ]] && cat >"$OUT.stdin"
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

# Record a visibility for the stub: vis owner/repo public|private|internal
vis() { printf '%s %s\n' "$1" "$2" >>"$VIS"; }

# cd into a repo whose only remote is the private me/secret.
private_repo() {
    setup_git_repo
    git remote add origin git@github.com:me/secret.git
    vis me/secret private
}

# No visibility lookup reached gh.
refute_lookups() { [ ! -e "$OUT.lookups" ]; }

# A bare `! cmd` never fails a bats test (set -e ignores negation).
refute() { ! "$@"; }
# Clear the previous call's log so a refusal is seen as nothing reaching gh.
gh_run() {
    rm -f "$OUT" "$OUT.lookups"
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

@test "a private session may not post to a named public repo" {
    private_repo
    vis org/proj public
    gh_run issue create -R org/proj --title t --body "$GEN"
    assert_refused
    [[ "$output" == *"org/proj is public; ask the user"* ]]
    [[ "$output" != *"wrapper-allow-public"* ]]
}

@test "a private session may write to private and internal repos" {
    private_repo
    vis me/other private
    vis corp/tool internal
    gh_run pr comment 1 -R me/other --body "$GEN"
    assert_passed
    gh_run pr comment 1 -R corp/tool --body "$GEN"
    assert_passed
}

@test "a failed visibility lookup is refused and says so" {
    private_repo
    gh_run issue comment 1 -R ghost/repo --body "$GEN"
    assert_refused
    [[ "$output" == *"looking up ghost/repo failed; retry"* ]]
}

@test "without -R every github remote of cwd is a target" {
    private_repo
    git remote add upstream https://github.com/org/proj
    vis org/proj public
    gh_run issue comment 1 --body "$GEN"
    assert_refused
    [[ "$output" == *"org/proj is public; pass -R owner/repo"* ]]
    gh_run issue comment 1 -R me/secret --body "$GEN"
    assert_passed
}

@test "a gh repo set-default choice is a target" {
    private_repo
    vis org/proj public
    git config remote.origin.gh-resolved org/proj
    gh_run issue comment 1 --body "$GEN"
    assert_refused
    git config remote.origin.gh-resolved base
    gh_run issue comment 1 --body "$GEN"
    assert_passed
}

@test "global -R, URL arguments and GH_REPO are targets" {
    private_repo
    vis org/proj public
    gh_run -R org/proj issue comment 1 --body "$GEN"
    assert_refused
    gh_run --repo=org/proj issue comment 1 --body "$GEN"
    assert_refused
    gh_run pr comment https://github.com/org/proj/pull/1 --body "$GEN"
    assert_refused
    GH_REPO=org/proj gh_run issue comment 1 --body "$GEN"
    assert_refused
}

@test "public sessions and non-repos are unrestricted" {
    vis org/proj public
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_passed
    refute_lookups
    setup_git_repo
    git remote add origin https://github.com/me/pub.git
    vis me/pub public
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_passed
}

@test "an unknown session remote makes the session private" {
    setup_git_repo
    git remote add origin git@github.com:me/mystery.git
    vis org/proj public
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_refused
}

@test "NN_SESSION_DIR keeps the session private after cd" {
    private_repo
    export NN_SESSION_DIR="$REPO_DIR"
    cd "$BATS_TEST_TMPDIR/work"
    vis org/proj public
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_refused
}

@test "allowlisted public repos may be written to" {
    private_repo
    vis org/proj public
    printf '# embargo lifted\nOrg/Proj\n' >"$HOME/.config/gh/wrapper-allow-public"
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_passed
}

@test "reads are never checked" {
    private_repo
    vis org/proj public
    gh_run issue view 1 -R org/proj
    assert_passed
    refute_lookups
}

@test "issue transfer checks the destination" {
    private_repo
    vis org/proj public
    gh_run issue transfer 1 org/proj
    assert_refused
    vis me/other private
    gh_run issue transfer 1 me/other
    assert_passed
}

@test "release create and upload are checked" {
    private_repo
    vis org/proj public
    gh_run release create v1 -R org/proj --notes x
    assert_refused
    gh_run release upload v1 secret.txt -R org/proj
    assert_refused
    gh_run release upload v1 secret.txt
    assert_passed
}

@test "a private session may not create or edit gists" {
    private_repo
    gh_run gist create notes.md
    assert_refused
    [[ "$output" == *"gists are readable by anyone"* ]]
    gh_run gist edit abc123
    assert_refused
    gh_run gist view abc123
    assert_passed
}

@test "a public session may create gists" {
    setup_git_repo
    git remote add origin https://github.com/me/pub.git
    vis me/pub public
    gh_run gist create notes.md
    assert_passed
}

@test "lookups print nothing to stderr" {
    private_repo
    vis me/other private
    bats_require_minimum_version 1.5.0
    run --separate-stderr "$GH" pr comment 1 -R me/other --body "$GEN"
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}

@test "unset HOME outside a session prints nothing to stderr" {
    bats_require_minimum_version 1.5.0
    run --separate-stderr env -u CLAUDECODE -u HOME "$GH" --version
    [ -z "$stderr" ]
}

@test "issue transfer from a public remote hints at -R" {
    private_repo
    git remote add upstream https://github.com/org/proj
    vis org/proj public
    vis me/other private
    gh_run issue transfer 1 me/other
    assert_refused
    [[ "$output" == *"pass -R owner/repo"* ]]
}

@test "a private session's api writes are checked by repo path" {
    private_repo
    vis org/proj public
    gh_run api repos/org/proj/issues -f title=t -f body="$GEN"
    assert_refused
    [[ "$output" == *"org/proj is public; ask the user"* ]]
    gh_run api -X DELETE /repos/org/proj/labels/x
    assert_refused
    gh_run api https://api.github.com/repos/org/proj/issues/1/comments -f body="$GEN"
    assert_refused
    gh_run api repos/me/secret/issues -f title=t -f body="$GEN"
    assert_passed
}

@test "api {owner}/{repo} placeholders resolve to cwd's remotes" {
    private_repo
    gh_run api 'repos/{owner}/{repo}/issues/1/comments' -f body="$GEN"
    assert_passed
    git remote add upstream git@github.com:org/proj.git
    vis org/proj public
    gh_run api 'repos/{owner}/{repo}/issues/1/comments' -f body="$GEN"
    assert_refused
    [[ "$output" == *"instead of {owner}/{repo}"* ]]
}

@test "api writes outside repos/ are refused unless exempt" {
    private_repo
    gh_run api gists -f description=x
    assert_refused
    [[ "$output" == *"can't be determined"* ]]
    [[ "$output" != *"-R"* ]]
    gh_run api markdown -f text=hi
    assert_passed
    gh_run api -X PATCH notifications/threads/1
    assert_passed
    gh_run api -X PUT user/starred/org/proj
    assert_passed
}

@test "api reads are never checked" {
    private_repo
    vis org/proj public
    gh_run api repos/org/proj/issues
    assert_passed
    gh_run api -X GET repos/org/proj/issues -f state=open
    assert_passed
    refute_lookups
}

@test "a private session's graphql mutations are judged by cwd's repo" {
    private_repo
    q='mutation { resolveReviewThread(input: {threadId: "PRRT_x"}) { clientMutationId } }'
    gh_run api graphql -f "query=$q"
    assert_passed
    git remote add upstream https://github.com/org/proj
    vis org/proj public
    gh_run api graphql -f "query=$q"
    assert_refused
    [[ "$output" == *"set GH_REPO=owner/repo to the repository it writes to"* ]]
    gh_run api graphql -f 'query={ viewer { login } }'
    assert_passed
}

@test "public sessions' graphql mutations need no lookup of a target" {
    q='mutation { resolveReviewThread(input: {threadId: "PRRT_x"}) { clientMutationId } }'
    gh_run api graphql -f "query=$q"
    assert_passed
    refute_lookups
}

cred() {
    run env "$@" bash -c "printf '%b' \"\$REQ\" | '$GH' auth git-credential \"\$VERB\""
}

@test "a private session's git pushes to public repos get no credentials" {
    private_repo
    vis org/proj public
    REQ='protocol=https\nhost=github.com\npath=org/proj.git\n\n' VERB=get cred
    [ "$status" -eq 1 ]
    [[ "$output" == *"org/proj is public"* ]]
    [ ! -e "$OUT" ]
    rm -f "$OUT.stdin"
    export REQ='protocol=https\nhost=github.com\npath=me/secret.git\n\n'
    VERB=get cred
    [ "$status" -eq 0 ]
    printf '%b' "$REQ" >"$BATS_TEST_TMPDIR/expected"
    cmp "$OUT.stdin" "$BATS_TEST_TMPDIR/expected"
}

@test "the push guard reads the session repo despite git's GIT_DIR" {
    private_repo
    export NN_SESSION_DIR="$PWD"
    mkdir "$BATS_TEST_TMPDIR/pub"
    cd "$BATS_TEST_TMPDIR/pub"
    git init -q
    git remote add origin https://github.com/org/proj.git
    vis org/proj public
    REQ='protocol=https\nhost=github.com\npath=org/proj.git\n\n' VERB=get \
        cred GIT_DIR="$BATS_TEST_TMPDIR/pub/.git"
    [ "$status" -eq 1 ]
    [[ "$output" == *"org/proj is public"* ]]
}

@test "a credential request without a path is refused in an nn private session" {
    private_repo
    export NN_SESSION_DIR="$PWD"
    REQ='protocol=https\nhost=github.com\n\n' VERB=get cred
    [ "$status" -eq 1 ]
    [[ "$output" == *"useHttpPath"* ]]
    [ ! -e "$OUT.stdin" ]
}

@test "credential store and erase pass through in a private session" {
    private_repo
    for verb in store erase; do
        rm -f "$OUT.stdin"
        REQ='protocol=https\nhost=github.com\nusername=x\npassword=y\n\n' VERB=$verb cred
        [ "$status" -eq 0 ]
        grep -qx 'password=y' "$OUT.stdin"
    done
}

@test "a credential request without a path passes outside nn" {
    private_repo
    unset NN_SESSION_DIR
    export REQ='protocol=https\nhost=github.com\n\n'
    VERB=get cred
    [ "$status" -eq 0 ]
    printf '%b' "$REQ" >"$BATS_TEST_TMPDIR/expected"
    cmp "$OUT.stdin" "$BATS_TEST_TMPDIR/expected"
}

@test "credential requests for other hosts do no lookups" {
    private_repo
    export REQ='protocol=https\nhost=example.com\npath=org/proj.git\n\n'
    VERB=get cred
    [ "$status" -eq 0 ]
    refute_lookups
    printf '%b' "$REQ" >"$BATS_TEST_TMPDIR/expected"
    cmp "$OUT.stdin" "$BATS_TEST_TMPDIR/expected"
}

@test "a public session's push credentials pass through" {
    setup_git_repo
    git remote add origin https://github.com/org/proj.git
    vis org/proj public
    export REQ='protocol=https\nhost=github.com\npath=org/proj.git\n\n'
    VERB=get cred
    [ "$status" -eq 0 ]
    printf '%b' "$REQ" >"$BATS_TEST_TMPDIR/expected"
    cmp "$OUT.stdin" "$BATS_TEST_TMPDIR/expected"
}

# nn sets GH_PATH to the wrapper; finding the real gh must not follow it.
@test "GH_PATH naming the wrapper still reaches real gh, which keeps GH_PATH" {
    stub_command gh 'printf "%s\n" "$GH_PATH" >"$OUT"'
    GH_PATH="$GH" gh_run auth git-credential get </dev/null
    [ "$status" -eq 0 ]
    [ "$(cat "$OUT")" = "$GH" ]
}
