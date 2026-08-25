#!/usr/bin/env bats

# Tests for bin/tag-release flag and env-var behavior. The tests stand up a
# throwaway git repo + bare remote and shadow gh/claude with mocks on PATH so
# the script can run end-to-end without touching the network.
#
# Run with: bats test/tag-release.bats

# `run !` (negated assertion) requires bats >= 1.5.0.
bats_require_minimum_version 1.5.0

setup() {
    SCRIPT_PATH="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/bin/tag-release"

    TMP="$(mktemp -d -t tag-release-test-XXXXXX)"
    REPO="$TMP/repo"
    REMOTE="$TMP/remote.git"
    BIN="$TMP/bin"
    MOCK_LOG="$TMP/mock.log"

    mkdir -p "$BIN"
    : >"$MOCK_LOG"

    # Bare remote so `git push origin <tag>` can succeed in tests that exercise
    # the non-dry-run path.
    git init --quiet --bare "$REMOTE"

    git init --quiet -b main "$REPO"
    (
        cd "$REPO" || return
        git config user.email "test@example.com"
        git config user.name "Test"
        git remote add origin "$REMOTE"
        echo init >README
        git add README
        git commit --quiet -m "init"
        git push --quiet -u origin main
    )

    # gh mock: handles the four subcommands the script invokes. Logs the call
    # for tests that want to assert no `release create` happened.
    cat >"$BIN/gh" <<'GH_MOCK'
#!/bin/bash
echo "gh $*" >> "$MOCK_LOG"
case "$1" in
    auth)
        # `gh auth status` — pretend we're logged in.
        exit 0
        ;;
    pr)
        # `gh pr list ...` — return $GH_PR_LIST_JSON if set, otherwise an empty
        # array so the script proceeds with zero PRs and skips the claude path.
        if [ -n "${GH_PR_LIST_JSON:-}" ]; then
            echo "$GH_PR_LIST_JSON"
        else
            echo "[]"
        fi
        ;;
    release)
        # `gh release create ...` — exit non-zero when the test asks us to,
        # otherwise pretend it succeeded.
        if [ -n "${GH_FAIL_RELEASE:-}" ]; then
            echo "MOCK: simulated gh release create failure" >&2
            exit 1
        fi
        exit 0
        ;;
    repo)
        # `gh repo view --json nameWithOwner -q .nameWithOwner`
        echo "owner/repo"
        ;;
    *)
        echo "gh mock: unhandled subcommand: $*" >&2
        exit 99
        ;;
esac
GH_MOCK
    chmod +x "$BIN/gh"

    # Use a clean PATH so any system-installed claude doesn't accidentally
    # satisfy the precheck. /usr/bin and /bin still expose git, jq, mktemp, etc.
    export PATH="$BIN:/usr/bin:/bin"
    export MOCK_LOG
}

teardown() {
    cd /
    rm -rf "$TMP"
}

# Drop a stub claude into $BIN so the precheck passes and (if invoked)
# returns canned text.
install_claude_mock() {
    cat >"$BIN/claude" <<'CLAUDE_MOCK'
#!/bin/bash
echo "claude $*" >> "$MOCK_LOG"
echo "- mocked summary"
CLAUDE_MOCK
    chmod +x "$BIN/claude"
}

@test "--help prints usage and exits 0" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: tag-release"* ]]
    [[ "$output" == *"--no-summary"* ]]
    [[ "$output" == *"--dry-run"* ]]
}

@test "unknown flag exits 2 with error message" {
    run "$SCRIPT_PATH" --bogus
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown option: --bogus"* ]]
}

@test "--no-summary skips the claude precheck" {
    cd "$REPO" || return
    # No claude on PATH; --no-summary must not error on its absence.
    run "$SCRIPT_PATH" --no-summary --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run"* ]]
    # Verify the mock claude was never invoked.
    run ! grep -q "^claude " "$MOCK_LOG"
}

@test "default mode requires claude on PATH" {
    cd "$REPO" || return
    run "$SCRIPT_PATH" --dry-run --yes
    [ "$status" -eq 1 ]
    [[ "$output" == *"'claude' CLI not found"* ]]
}

@test "--dry-run skips git tag, push, and gh release create" {
    cd "$REPO" || return
    run "$SCRIPT_PATH" --no-summary --dry-run 2099-12-31-99
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run"* ]]
    [[ "$output" == *"would create tag 2099-12-31-99"* ]]
    # No tag should have been created locally.
    run git -C "$REPO" tag --list "2099-12-31-99"
    [ -z "$output" ]
    # `gh release create` must not have been called.
    run ! grep -q "^gh release create" "$MOCK_LOG"
}

@test "--yes skips the confirmation prompt" {
    cd "$REPO" || return
    install_claude_mock
    # Closing stdin would cause `read` to fail under set -e. With --yes the
    # prompt is bypassed entirely, so the script must run to completion.
    run bash -c "'$SCRIPT_PATH' --yes 2099-12-31-50 </dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Proceeding without prompt"* ]]
    [[ "$output" == *"Tag 2099-12-31-50 pushed to origin"* ]]
    grep -q "^gh release create" "$MOCK_LOG"
    # Verify the tag actually got created and pushed to the bare remote.
    run git -C "$REMOTE" tag --list "2099-12-31-50"
    [[ "$output" == *"2099-12-31-50"* ]]
}

@test "TAG_RELEASE_YES env var is equivalent to --yes" {
    cd "$REPO" || return
    install_claude_mock
    TAG_RELEASE_YES=1 run bash -c "'$SCRIPT_PATH' 2099-12-31-51 </dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Proceeding without prompt"* ]]
}

@test "TAG_RELEASE_NO_SUMMARY env var skips claude" {
    cd "$REPO" || return
    # No claude on PATH; setting the env var must avoid the precheck.
    TAG_RELEASE_NO_SUMMARY=1 run "$SCRIPT_PATH" --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run"* ]]
}

@test "TAG_RELEASE_DRY_RUN env var skips tagging" {
    cd "$REPO" || return
    TAG_RELEASE_DRY_RUN=1 run "$SCRIPT_PATH" --no-summary --yes 2099-12-31-52
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run"* ]]
    run ! grep -q "^gh release create" "$MOCK_LOG"
}

@test "writes tag=... to GITHUB_OUTPUT when set" {
    cd "$REPO" || return
    out_file="$TMP/gh_output"
    : >"$out_file"
    GITHUB_OUTPUT="$out_file" run "$SCRIPT_PATH" --no-summary --dry-run --yes 2099-12-31-53
    [ "$status" -eq 0 ]
    grep -q "^tag=2099-12-31-53$" "$out_file"
}

@test "writes release notes to GITHUB_STEP_SUMMARY on dry run" {
    cd "$REPO" || return
    summary_file="$TMP/step_summary"
    : >"$summary_file"
    GITHUB_STEP_SUMMARY="$summary_file" run "$SCRIPT_PATH" --no-summary --dry-run --yes 2099-12-31-54
    [ "$status" -eq 0 ]
    grep -q "Tag Release (dry run)" "$summary_file"
    grep -q "2099-12-31-54" "$summary_file"
}

@test "rejects non-main branches even with --yes" {
    cd "$REPO" || return
    git checkout --quiet -b feature
    run "$SCRIPT_PATH" --no-summary --dry-run --yes
    [ "$status" -eq 1 ]
    [[ "$output" == *"must be on the 'main' branch"* ]]
}

@test "allows detached HEAD when GITHUB_ACTIONS=true and ref is main" {
    cd "$REPO" || return
    git checkout --quiet --detach HEAD
    GITHUB_ACTIONS=true GITHUB_REF=refs/heads/main \
        run "$SCRIPT_PATH" --no-summary --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run"* ]]
}

@test "rejects detached HEAD without GitHub Actions context" {
    cd "$REPO" || return
    git checkout --quiet --detach HEAD
    run "$SCRIPT_PATH" --no-summary --dry-run --yes
    [ "$status" -eq 1 ]
    [[ "$output" == *"detached HEAD"* ]]
}

@test "gh release create failure writes notes to GITHUB_STEP_SUMMARY" {
    cd "$REPO" || return
    install_claude_mock
    summary_file="$TMP/step_summary"
    : >"$summary_file"
    GITHUB_STEP_SUMMARY="$summary_file" GH_FAIL_RELEASE=1 \
        run bash -c "'$SCRIPT_PATH' --no-summary --yes 2099-12-31-77 </dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" == *"GitHub Release creation failed"* ]]
    [[ "$output" == *"Recover with: gh release create 2099-12-31-77"* ]]
    grep -q "Tag Release (release creation failed)" "$summary_file"
    grep -q "2099-12-31-77" "$summary_file"
    # Tag was pushed even though release creation failed — that's the recovery
    # contract the script's recover hint relies on.
    run git -C "$REMOTE" tag --list "2099-12-31-77"
    [[ "$output" == *"2099-12-31-77"* ]]
}

@test "empty first positional arg auto-computes a tag" {
    cd "$REPO" || return
    out_file="$TMP/gh_output"
    : >"$out_file"
    # Mirrors how a wrapping workflow invokes the script when the `tag` input
    # is blank: tag-release "" "50"
    GITHUB_OUTPUT="$out_file" run "$SCRIPT_PATH" --no-summary --dry-run --yes "" "50"
    [ "$status" -eq 0 ]
    today=$(date +%Y-%m-%d)
    grep -qE "^tag=${today}-[0-9]{2}\$" "$out_file"
}

# Regression: the search-based query (gh pr list --search "merged:>X") is
# unreliable here — GitHub's search index is eventually consistent and can
# return empty arrays shortly after merges. The script must never go back to
# it.
@test "does not call gh pr list with --search" {
    cd "$REPO" || return
    run "$SCRIPT_PATH" --no-summary --dry-run --yes 2099-12-31-93
    [ "$status" -eq 0 ]
    run ! grep -q '^gh pr list .*--search' "$MOCK_LOG"
}

@test "client-side filter excludes PRs merged at or before the last tag" {
    cd "$REPO" || return
    # The tag points at the init commit ("now"-ish); injected PRs have
    # mergedAt far in the past and far in the future so the filter result is
    # deterministic regardless of when the test runs.
    git tag 2020-01-01-01
    GH_PR_LIST_JSON='[{"number":100,"title":"old PR","body":"","author":{"login":"alice"},"mergedAt":"1970-01-01T00:00:00Z"},{"number":200,"title":"new PR","body":"","author":{"login":"bob"},"mergedAt":"2099-12-31T23:59:59Z"}]' \
        run "$SCRIPT_PATH" --no-summary --dry-run --yes 2099-12-31-94
    [ "$status" -eq 0 ]
    [[ "$output" == *"Found 1 merged PR(s) since last tag"* ]]
    [[ "$output" == *"new PR"* ]]
    [[ "$output" != *"old PR"* ]]
}

@test "warns about truncation when oldest fetched PR is newer than cutoff" {
    cd "$REPO" || return
    # MAX_PRS=2 and we inject exactly 2 PRs, both newer than the cutoff —
    # so older in-window PRs may have been pushed off the page.
    GH_PR_LIST_JSON='[{"number":1,"title":"a","body":"","author":{"login":"alice"},"mergedAt":"2099-12-31T23:59:59Z"},{"number":2,"title":"b","body":"","author":{"login":"bob"},"mergedAt":"2099-06-01T00:00:00Z"}]' \
        run "$SCRIPT_PATH" --no-summary --dry-run --yes 2099-12-31-95 2
    [ "$status" -eq 0 ]
    [[ "$output" == *"PR list may be truncated"* ]]
}

@test "does not warn about truncation when oldest fetched PR predates cutoff" {
    cd "$REPO" || return
    # MAX_PRS=2, page is full, but the oldest PR on the page is already
    # older than the cutoff — truncation can't be hiding an in-window PR.
    GH_PR_LIST_JSON='[{"number":1,"title":"a","body":"","author":{"login":"alice"},"mergedAt":"2099-12-31T23:59:59Z"},{"number":2,"title":"b","body":"","author":{"login":"bob"},"mergedAt":"1970-01-01T00:00:00Z"}]' \
        run "$SCRIPT_PATH" --no-summary --dry-run --yes 2099-12-31-96 2
    [ "$status" -eq 0 ]
    [[ "$output" != *"PR list may be truncated"* ]]
}

@test "MAX_PRS=0 does not spuriously trigger the truncation warning" {
    cd "$REPO" || return
    # Degenerate case: $MAX_PRS=0 means $ALL_COUNT=0=$MAX_PRS, which would
    # have entered the truncation check and tried to take min_by of an empty
    # array (jq error) without the $ALL_COUNT -gt 0 guard.
    run "$SCRIPT_PATH" --no-summary --dry-run --yes 2099-12-31-98 0
    [ "$status" -eq 0 ]
    [[ "$output" != *"PR list may be truncated"* ]]
}

@test "client-side filter compares timestamps in UTC, not lexically" {
    cd "$REPO" || return
    # Build a commit whose %cI is in -04:00 and tag it. The injected PR's
    # mergedAt is in UTC (Z suffix) and is one hour BEFORE the tag in real
    # time, but lexicographically the strings sort the other way:
    #
    #   tag (%cI):   "2026-05-11T05:00:00-04:00"  = 2026-05-11T09:00:00Z
    #   PR mergedAt: "2026-05-11T08:00:00Z"       (1h before tag)
    #   lex compare: "2026-05-11T08:00:00Z" > "2026-05-11T05:00:00-04:00"
    #                (because 'Z' (0x5a) > '-' (0x2d) at byte 19)
    #
    # A naive lex filter would wrongly include the PR. The script must use a
    # UTC-aware comparison and exclude it.
    GIT_COMMITTER_DATE="2026-05-11T05:00:00-04:00" \
        GIT_AUTHOR_DATE="2026-05-11T05:00:00-04:00" \
        git commit --quiet --allow-empty -m "tz-test commit"
    git tag tz-tag
    GH_PR_LIST_JSON='[{"number":42,"title":"older PR","body":"","author":{"login":"alice"},"mergedAt":"2026-05-11T08:00:00Z"}]' \
        run "$SCRIPT_PATH" --no-summary --dry-run --yes 2099-12-31-97
    [ "$status" -eq 0 ]
    [[ "$output" == *"Found 0 merged PR(s) since last tag"* ]]
    [[ "$output" != *"older PR"* ]]
}
