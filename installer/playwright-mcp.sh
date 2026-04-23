#!/bin/bash

set -eu -o pipefail

# Installs @playwright/mcp globally plus the chromium it drives, and sets up
# an npx wrapper at ~/local/bin/npx that intercepts @playwright/mcp calls so
# the plugin's `npx @playwright/mcp@latest` invocation doesn't hit the npm
# registry on every MCP launch.

if ! command -v npm >/dev/null; then
    echo "npm not in PATH — install node first" >&2
    exit 1
fi

npm install -g @playwright/mcp@latest

# Downloads to ~/.cache/ms-playwright/chromium-*. Idempotent — skips when the
# current playwright version already has the browser cached.
npx playwright install chromium

# Resolve the playwright-mcp binary path at install time so the wrapper
# doesn't depend on ~/.npm-packages/bin being in PATH.
pw_mcp_bin="$(npm prefix -g)/bin/playwright-mcp"
if [[ ! -x $pw_mcp_bin ]]; then
    echo "playwright-mcp not found at $pw_mcp_bin after install" >&2
    exit 1
fi

# ~/local/bin is ahead of system paths in dotfiles' PATH, so this wrapper
# takes priority over /usr/bin/npx without touching system files.
npx_bin="$HOME/local/bin/npx"
mkdir -p "$(dirname "$npx_bin")"

cat >"$npx_bin" <<EOF
#!/bin/bash
# Strip the @playwright/mcp spec and exec the installed binary directly.
# playwright-mcp takes zero positional args and errors if the spec is passed.
if [[ "\$*" == *"@playwright/mcp"* ]]; then
    args=()
    for arg in "\$@"; do
        [[ \$arg == @playwright/* ]] && continue
        args+=("\$arg")
    done
    exec "$pw_mcp_bin" "\${args[@]}"
fi
exec /usr/bin/npx "\$@"
EOF
chmod +x "$npx_bin"
