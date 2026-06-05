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

verdict=$(nono why --path "$path" --op read --profile "$profile" 2>&1 | head -1)

if [[ $verdict == ALLOWED* ]]; then
    echo "ok: $profile grants read on $path"
else
    echo "FAIL: $profile does not grant read on $path" >&2
    nono why --path "$path" --op read --profile "$profile" >&2
    exit 1
fi
