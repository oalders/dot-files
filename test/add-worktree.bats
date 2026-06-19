#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    ADD_WORKTREE="$BIN_DIR/add-worktree"
    # Isolate HOME so the worktree the script creates lives under the
    # per-test sandbox, not the dev's real ~/.worktree.
    HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    export HOME
    # bin/add-worktree refuses to run from inside a tmux session and
    # tries to start one if tmux is around. Force neither path.
    export MY_INSIDE_TMUX=false
    stub_command pgrep 'exit 1'
    # Tests use generic branch names so the fix-/gh- branches that call
    # `gh issue edit` / `gh pr checkout` aren't exercised; stub anyway.
    stub_command gh 'exit 0'
    export GIT_CEILING_DIRECTORIES
    GIT_CEILING_DIRECTORIES="$(dirname "$BATS_TEST_TMPDIR")"
}

@test "add-worktree initializes submodules in the new worktree" {
    # protocol.file.allow is needed because the submodule URL is a local
    # path; modern git denies file:// transport by default. HOME is the
    # sandbox so --global writes there, not the dev's real config.
    git config --global protocol.file.allow always
    git config --global init.defaultBranch main
    git config --global user.email t@example.com
    git config --global user.name T

    SUB_SRC="$BATS_TEST_TMPDIR/sub-src"
    mkdir -p "$SUB_SRC"
    (
        cd "$SUB_SRC"
        git init -q
        echo sub >sub-file
        git add sub-file
        git -c commit.gpgsign=false commit -q -m init
    )

    setup_git_repo
    git submodule add -q "$SUB_SRC" mysub
    git -c commit.gpgsign=false commit -q -m "add submodule"
    [ -f mysub/sub-file ]

    run "$ADD_WORKTREE" feature-branch
    [ "$status" -eq 0 ]

    local date_stamp repo_name worktree
    date_stamp="$(date +%Y-%m-%d)"
    repo_name="$(basename "$REPO_DIR")"
    worktree="$HOME/.worktree/$repo_name/$date_stamp/feature-branch"

    [ -f "$worktree/mysub/sub-file" ]
}

@test "add-worktree is a no-op for submodules in a repo without any" {
    setup_git_repo
    run "$ADD_WORKTREE" feature-branch
    [ "$status" -eq 0 ]

    local date_stamp repo_name worktree
    date_stamp="$(date +%Y-%m-%d)"
    repo_name="$(basename "$REPO_DIR")"
    worktree="$HOME/.worktree/$repo_name/$date_stamp/feature-branch"

    [ -d "$worktree" ]
    [ ! -f "$worktree/.gitmodules" ]
}

@test "add-worktree accepts -f and creates the worktree" {
    # Exercises the non-empty force=(-f) array branch: -f must reach
    # `git worktree add` as a real flag, and an empty force must not inject
    # a stray empty arg (covered by the other tests' default path).
    setup_git_repo
    run "$ADD_WORKTREE" -f feature-branch
    [ "$status" -eq 0 ]

    local date_stamp repo_name worktree
    date_stamp="$(date +%Y-%m-%d)"
    repo_name="$(basename "$REPO_DIR")"
    worktree="$HOME/.worktree/$repo_name/$date_stamp/feature-branch"

    [ -d "$worktree" ]
}

@test "add-worktree queues fix-gh-issue for fix-<n> branches" {
    setup_git_repo
    # fix-<n> is an issue branch: it adds the "in progress" label via
    # `gh issue edit` and takes the marker path, but must never hit the
    # `gh pr checkout` path (that's for gh-<n> PR branches). Allow `issue
    # edit`; fail loud on any `pr checkout` so the marker write can't
    # silently coexist with a stray checkout.
    stub_command gh 'case "$*" in
        "pr checkout"*) echo "gh pr checkout must not be called for issue branches" >&2; exit 1 ;;
        *) exit 0 ;;
    esac'
    run "$ADD_WORKTREE" fix-952
    [ "$status" -eq 0 ]

    local date_stamp repo_name worktree
    date_stamp="$(date +%Y-%m-%d)"
    repo_name="$(basename "$REPO_DIR")"
    worktree="$HOME/.worktree/$repo_name/$date_stamp/fix-952"

    [ -f "$worktree/.tmp/fix-gh-issue.pending" ]
    grep -Fxq '/kitchen-sink:fix-gh-issue' "$worktree/.tmp/fix-gh-issue.pending"
}

@test "add-worktree tries to create the in progress label for fix-<n> branches" {
    setup_git_repo
    export GH_LOG="$BATS_TEST_TMPDIR/gh.log"
    stub_command gh 'printf "%s\n" "$*" >>"$GH_LOG"
exit 0'
    run "$ADD_WORKTREE" fix-952
    [ "$status" -eq 0 ]
    # Created with a traffic-light green color.
    grep -q "label create in progress --color 2ECC40" "$GH_LOG"
}

@test "add-worktree continues when gh issue edit fails to add the label" {
    setup_git_repo
    # Simulate the label add failing (e.g. label missing, or no perms). The
    # script must warn and carry on, not abort worktree setup.
    stub_command gh 'case "$*" in
        "issue edit"*) echo "could not add label: not found" >&2; exit 1 ;;
        *) exit 0 ;;
    esac'
    run "$ADD_WORKTREE" fix-952
    [ "$status" -eq 0 ]

    local date_stamp repo_name worktree
    date_stamp="$(date +%Y-%m-%d)"
    repo_name="$(basename "$REPO_DIR")"
    worktree="$HOME/.worktree/$repo_name/$date_stamp/fix-952"

    [ -f "$worktree/.tmp/fix-gh-issue.pending" ]
}

@test "add-worktree continues when it lacks permission to create the label" {
    setup_git_repo
    # Simulate `gh label create` being denied (403). The script must warn
    # and carry on to label the issue and finish setup.
    stub_command gh 'case "$*" in
        "label create"*) echo "HTTP 403: Resource not accessible by integration" >&2; exit 1 ;;
        *) exit 0 ;;
    esac'
    run "$ADD_WORKTREE" fix-952
    [ "$status" -eq 0 ]

    local date_stamp repo_name worktree
    date_stamp="$(date +%Y-%m-%d)"
    repo_name="$(basename "$REPO_DIR")"
    worktree="$HOME/.worktree/$repo_name/$date_stamp/fix-952"

    [ -f "$worktree/.tmp/fix-gh-issue.pending" ]
}

@test "add-worktree queues nothing for non-fix branches" {
    setup_git_repo
    run "$ADD_WORKTREE" feature-branch
    [ "$status" -eq 0 ]

    local date_stamp repo_name worktree
    date_stamp="$(date +%Y-%m-%d)"
    repo_name="$(basename "$REPO_DIR")"
    worktree="$HOME/.worktree/$repo_name/$date_stamp/feature-branch"

    [ ! -f "$worktree/.tmp/fix-gh-issue.pending" ]
}
