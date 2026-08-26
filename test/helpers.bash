# Test helpers shared across bats files.

# Path to the bin/ directory under test (resolved from the test file's location).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

# Per-test sandbox. Bats sets BATS_TEST_TMPDIR; we use it as the base
# for stub PATH and any temp git repos. Bats runs each test in its own
# subshell, so PATH/STUB_DIR mutations don't leak between tests — no
# teardown needed.
setup_sandbox() {
    STUB_DIR="$BATS_TEST_TMPDIR/stubs"
    mkdir -p "$STUB_DIR"
    PATH="$STUB_DIR:$PATH"
    export PATH STUB_DIR
}

# Install a fake command in the stub PATH.
# Usage: stub_command <name> <body>
#   The body is the script content; it can reference "$@" etc.
stub_command() {
    : "${STUB_DIR:?stub_command called before setup_sandbox}"
    local name="$1"
    local body="$2"
    cat >"$STUB_DIR/$name" <<'EOF'
#!/usr/bin/env bash
EOF
    printf '%s\n' "$body" >>"$STUB_DIR/$name"
    chmod +x "$STUB_DIR/$name"
}

# Set up a fresh git repo with an initial commit in BATS_TEST_TMPDIR/repo
# and cd into it. After this, HEAD is on a branch with one commit and
# no remote configured.
setup_git_repo() {
    REPO_DIR="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO_DIR"
    cd "$REPO_DIR"
    git init -q -b main
    git config user.email "test@example.com"
    git config user.name "Test"
    echo "x" >file
    git add file
    git -c commit.gpgsign=false commit -q -m "init"
}

# Set up a "bare upstream" simulating a remote, and configure tracking.
# Caller must already be inside a repo (run setup_git_repo first).
# After this, the current branch is pushed to "origin" and tracking is set.
setup_upstream() {
    UPSTREAM_DIR="$BATS_TEST_TMPDIR/upstream.git"
    git init --bare -q "$UPSTREAM_DIR"
    git remote add origin "$UPSTREAM_DIR"
    git push -q -u origin HEAD
}

# Break the current branch's tracking config so `@{u}` no longer resolves,
# while the branch remains pushed to origin. Simulates the bug in #935:
# branch.<name>.remote set to a clone URL instead of "origin". Caller must
# already be inside a repo with the branch pushed (run setup_git_repo and
# setup_upstream first).
break_tracking_config() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    git config "branch.$branch.remote" "$UPSTREAM_DIR"
    git config "branch.$branch.merge" "refs/heads/$branch"
}

# Set up a feature worktree linked to the repo created by setup_git_repo +
# setup_upstream, ready for merge-pr's cleanup path.
# Usage: setup_feature_worktree [--with-submodule]
# Caller must already be inside the main repo (run setup_git_repo and
# setup_upstream first). After this:
#   - WORKTREE_DIR holds a worktree on branch "feature" pushed to origin
#     with no unpushed commits;
#   - the caller's cwd is the worktree;
#   - with --with-submodule, the worktree contains a committed submodule.
setup_feature_worktree() {
    local with_submodule=""
    if [[ "${1:-}" == "--with-submodule" ]]; then
        with_submodule="yes"
    fi

    WORKTREE_DIR="$BATS_TEST_TMPDIR/feature-wt"
    git worktree add -q "$WORKTREE_DIR" -b feature
    cd "$WORKTREE_DIR"
    git config user.email "test@example.com"
    git config user.name "Test"

    if [[ -n "$with_submodule" ]]; then
        # A submodule needs a real repo to point at. Create one and add
        # it from inside the worktree. Local submodule adds require
        # protocol.file.allow=always on modern git.
        local sub_src="$BATS_TEST_TMPDIR/submodule-src"
        mkdir -p "$sub_src"
        git -C "$sub_src" init -q -b main
        git -C "$sub_src" config user.email "test@example.com"
        git -C "$sub_src" config user.name "Test"
        echo "sub" >"$sub_src/subfile"
        git -C "$sub_src" add subfile
        git -C "$sub_src" -c commit.gpgsign=false commit -q -m "sub init"

        git -c protocol.file.allow=always submodule add -q "$sub_src" sub
        git -c commit.gpgsign=false commit -q -m "add submodule"
    fi

    git push -q -u origin feature
}

# Set up a worktree *of* a submodule (as opposed to a worktree that merely
# contains one). Mirrors the real workflow where add-worktree is run from
# inside a submodule checkout: the linked worktree lives under the
# superproject's .git/modules/<name>, so merge-pr's teardown must resolve the
# submodule's own main working tree — not the superproject (#1029-style).
# Self-contained; does not require setup_git_repo first. After this:
#   - SUBMODULE_MAIN holds the submodule's main working tree (super/sub);
#   - WORKTREE_DIR holds a worktree of the submodule on branch "feature",
#     pushed to the submodule's origin with no unpushed commits;
#   - the caller's cwd is the worktree.
setup_submodule_feature_worktree() {
    local super="$BATS_TEST_TMPDIR/super"
    local sub_src="$BATS_TEST_TMPDIR/submodule-src"
    local sub_upstream="$BATS_TEST_TMPDIR/sub-upstream.git"

    # The submodule's origin repo, with one commit.
    mkdir -p "$sub_src"
    git -C "$sub_src" init -q -b main
    git -C "$sub_src" config user.email "test@example.com"
    git -C "$sub_src" config user.name "Test"
    echo "sub" >"$sub_src/subfile"
    git -C "$sub_src" add subfile
    git -C "$sub_src" -c commit.gpgsign=false commit -q -m "sub init"

    # Superproject embedding the submodule at path "sub". Local file adds
    # require protocol.file.allow=always on modern git.
    mkdir -p "$super"
    git -C "$super" init -q -b main
    git -C "$super" config user.email "test@example.com"
    git -C "$super" config user.name "Test"
    echo "top" >"$super/top"
    git -C "$super" add top
    git -C "$super" -c commit.gpgsign=false commit -q -m "init"
    git -C "$super" -c protocol.file.allow=always submodule add -q "$sub_src" sub
    git -C "$super" -c commit.gpgsign=false commit -q -m "add submodule"

    SUBMODULE_MAIN="$super/sub"

    # A bare origin for the submodule so merge-pr's push pre-flight resolves.
    # `submodule add` already set origin to sub_src; repoint it at the bare
    # upstream (a non-bare origin would reject the branch push).
    git init --bare -q "$sub_upstream"
    git -C "$SUBMODULE_MAIN" remote set-url origin "$sub_upstream"
    git -C "$SUBMODULE_MAIN" push -q -u origin main

    # The worktree of the submodule, on a pushed "feature" branch.
    WORKTREE_DIR="$BATS_TEST_TMPDIR/sub-feature-wt"
    git -C "$SUBMODULE_MAIN" worktree add -q "$WORKTREE_DIR" -b feature
    git -C "$WORKTREE_DIR" push -q -u origin feature
    cd "$WORKTREE_DIR"
}
