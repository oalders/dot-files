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
