#!/usr/bin/env bash

# Regression test for issue #948: the global Claude Code instructions
# (~/.claude/CLAUDE.md, a symlink to ~/dot-files/claude/CLAUDE.md) must be
# readable inside the oalders sandbox, or none of the global instructions
# reach the model in sandboxed sessions.
#
# Uses `nono why` rather than a full `nono run` so it validates the policy
# grant without needing to spin up the proxy/supervisor — runnable even from
# inside an existing sandbox.

set -eu -o pipefail

# Test the repo's own profile (resolved relative to this script) rather than
# the installed `oalders` symlink, so the test validates the source of truth
# and runs correctly from a worktree before the change is merged/symlinked.
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
profile="$repo_root/nono/oalders.json"
path="$HOME/.claude/CLAUDE.md"

# Capture once (stdout+stderr) so the failure path can echo the full output
# without a second invocation. nono why exits 0 for both ALLOWED and DENIED,
# so the verdict is read from the output: grab the first ALLOWED/DENIED line
# rather than head -1, so a stray stderr warning can't masquerade as it.
output=$(nono why --path "$path" --op read --profile "$profile" 2>&1)
verdict=$(printf '%s\n' "$output" | grep -m1 -E '^(ALLOWED|DENIED)' || true)

if [[ $verdict == ALLOWED* ]]; then
    echo "ok: $profile grants read on $path"
else
    echo "FAIL: $profile does not grant read on $path" >&2
    printf '%s\n' "$output" >&2
    exit 1
fi
