#!/bin/bash

set -eu -o pipefail

# Installs the version-pinned @playwright/mcp (see dot-files/package.json) plus
# the chromium it drives, and sets up an npx wrapper at ~/dot-files/bin/npx that
# intercepts @playwright/mcp calls so the plugin's `npx @playwright/mcp@latest`
# invocation runs the local pinned build instead of hitting the npm registry on
# every MCP launch. ~/dot-files/bin is ahead of ~/dot-files/node_modules/.bin in
# PATH, so the wrapper wins over the npm-installed npx without reordering PATH.

if ! command -v npm >/dev/null; then
    echo "npm not in PATH — install node first" >&2
    exit 1
fi

dotfiles="$HOME/dot-files"

# @playwright/mcp is version-pinned in dot-files/package.json (exact, so it
# can't drift on @latest between runs; dependabot proposes upgrades as PRs).
# installer/npm.sh's `npm install` brings it into the local node_modules — but
# ensure it's present so this script also works when run standalone. npm install
# is idempotent.
if [[ ! -d $dotfiles/node_modules/@playwright/mcp ]]; then
    (cd "$dotfiles" && npm install)
fi

pw_mcp_bin="$dotfiles/node_modules/.bin/playwright-mcp"
if [[ ! -x $pw_mcp_bin ]]; then
    echo "playwright-mcp not found at $pw_mcp_bin after install" >&2
    exit 1
fi

# @playwright/mcp pins its own playwright version (an alpha), which wants a
# specific chromium build revision. Driving that install through a bare
# `npx playwright install` resolves to whatever playwright npx happens to cache
# (often an older release) and downloads the wrong browser build, so the MCP
# launches against a chromium it doesn't match. Resolve the playwright CLI the
# way the MCP itself resolves the `playwright` module and install through that,
# so the browser revision always matches what the MCP drives. cli.js isn't an
# exported subpath, so resolve the package dir and join it.
pw_cli="$(cd "$dotfiles" && node -e '
    const path = require("path");
    const mcpDir = path.dirname(require.resolve("@playwright/mcp/package.json"));
    const pwPkg = require.resolve("playwright/package.json", { paths: [mcpDir] });
    process.stdout.write(path.join(path.dirname(pwPkg), "cli.js"));
')"
if [[ ! -f $pw_cli ]]; then
    echo "bundled playwright CLI not found at $pw_cli" >&2
    exit 1
fi

# Downloads to ~/.cache/ms-playwright/chromium-*. Idempotent — skips when the
# bundled playwright version already has the browser cached.
node "$pw_cli" install chromium

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
