# Test helpers shared across bats files.

# Path to the bin/ directory under test (resolved from the test file's location).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

# Per-test sandbox. Bats sets BATS_TEST_TMPDIR; we use it as the base
# for stub PATH and any temp git repos.
setup_sandbox() {
    STUB_DIR="$BATS_TEST_TMPDIR/stubs"
    mkdir -p "$STUB_DIR"
    PATH="$STUB_DIR:$PATH"
    export PATH
}

# Install a fake command in the stub PATH.
# Usage: stub_command <name> <body>
#   The body is the script content; it can reference "$@" etc.
stub_command() {
    local name="$1"
    local body="$2"
    cat >"$STUB_DIR/$name" <<EOF
#!/usr/bin/env bash
$body
EOF
    chmod +x "$STUB_DIR/$name"
}
