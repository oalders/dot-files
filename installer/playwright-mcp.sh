#!/bin/bash

set -eu -o pipefail

# Installs @playwright/mcp globally plus the chromium it drives, and sets up
# an npx wrapper at ~/dot-files/bin/npx that intercepts @playwright/mcp
# calls so the plugin's `npx @playwright/mcp@latest` invocation doesn't hit
# the npm registry on every MCP launch. ~/dot-files/bin is ahead of
# ~/dot-files/node_modules/.bin in PATH, so the wrapper wins over the
# npm-installed npx without having to reorder PATH.

if ! command -v npm >/dev/null; then
    echo "npm not in PATH — install node first" >&2
    exit 1
fi

npm install -g @playwright/mcp@latest

# @playwright/mcp pins its own playwright version (e.g. an alpha), which wants a
# specific chromium build revision. Driving that install through a bare
# `npx playwright install` resolves to whatever playwright npx happens to cache
# (often an older release) and downloads the wrong browser build, so the MCP
# launches against a chromium it doesn't match. Install through the playwright
# CLI bundled *inside* @playwright/mcp instead, so the browser revision always
# matches what the MCP drives.
mcp_dir="$(npm root -g)/@playwright/mcp"
pw_cli="$mcp_dir/node_modules/playwright/cli.js"
if [[ ! -f $pw_cli ]]; then
    echo "bundled playwright CLI not found at $pw_cli after install" >&2
    exit 1
fi

# Downloads to ~/.cache/ms-playwright/chromium-*. Idempotent — skips when the
# bundled playwright version already has the browser cached.
node "$pw_cli" install chromium

# Resolve the playwright-mcp binary path at install time so the wrapper
# doesn't depend on ~/.npm-packages/bin being in PATH.
pw_mcp_bin="$(npm prefix -g)/bin/playwright-mcp"
if [[ ! -x $pw_mcp_bin ]]; then
    echo "playwright-mcp not found at $pw_mcp_bin after install" >&2
    exit 1
fi

npx_bin="$HOME/dot-files/bin/npx"

# Short scratch base for the browser's temp profile; see the wrapper comment.
# Resolved at install time (like pw_mcp_bin) so the wrapper carries a literal.
# Matches the oalders-core filesystem.allow grant of /tmp/claude-<uid>, which is
# what makes this path writable inside the nono sandbox.
browser_tmp="/tmp/claude-$(id -u)/pw-mcp"

cat >"$npx_bin" <<EOF
#!/bin/bash
# Strip the @playwright/mcp spec and exec the installed binary directly.
# playwright-mcp takes zero positional args and errors if the spec is passed.
#
# --browser chromium: @playwright/mcp defaults to the "chrome" channel, i.e.
# system Google Chrome at /opt/google/chrome/chrome. Under the nono sandbox that
# binary SIGTRAPs on startup because its crashpad handler can't write
# ~/.config/google-chrome/Crash Reports and fatally aborts ("--database is
# required"; the same crash --chrome in bin/nn grants around for the
# superpowers-chrome MCP — see nono/CLAUDE.md). Playwright's own bundled Chrome
# for Testing only logs a *non-fatal* permission error for its crash-reports dir
# and keeps running, so point the MCP at the bundled build instead. It lives in
# the shared ~/.cache/ms-playwright bundle this installer seeds.
#
# --headless: the sandbox has no display, so a headed launch can't come up.
#
# TMPDIR: Chromium's process-singleton opens a Unix domain socket at
# <user-data-dir>/SingletonSocket, and Playwright puts that user-data-dir under
# \$TMPDIR. bin/nn sets TMPDIR=\$PWD/.tmp to keep scratch inside --allow-cwd; in
# a deep (dated) worktree that prefix plus the socket name overruns the ~108-char
# sun_path limit and Chromium FATALs ("Socket path too long"). Redirect just the
# browser's TMPDIR to the short, already-granted /tmp/claude-<uid> scratch base
# so the socket fits — the session-wide TMPDIR is left untouched. mkdir guards
# against a run where that base isn't writable (e.g. outside the sandbox): on
# failure we skip the override and fall back to the inherited TMPDIR.
#
# User-supplied args come last, so an explicit --browser/--headed still wins.
if [[ "\$*" == *"@playwright/mcp"* ]]; then
    args=()
    for arg in "\$@"; do
        [[ \$arg == @playwright/* ]] && continue
        args+=("\$arg")
    done
    mkdir -p "$browser_tmp" 2>/dev/null && export TMPDIR="$browser_tmp"
    exec "$pw_mcp_bin" --browser chromium --headless "\${args[@]}"
fi
exec /usr/bin/npx "\$@"
EOF
chmod +x "$npx_bin"
