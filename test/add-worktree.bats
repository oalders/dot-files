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
