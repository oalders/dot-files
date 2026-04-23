#!/bin/bash

set -eu -o pipefail

# Wires up Serena's MCP plumbing so Claude Code runs the locally-installed
# binary instead of re-fetching from git via `uvx --from git+...` on every
# MCP launch. Assumes serena-agent is already installed via `uv tool install`
# (installer/claude.sh owns that).

if ! command -v serena-mcp-server >/dev/null; then
    echo "serena-mcp-server not in PATH — run installer/claude.sh first" >&2
    exit 1
fi

# On startup Serena tries to open a browser for its web dashboard. Silence it
# so MCP handshakes don't hang in headless environments and don't spawn tabs
# on every launch on desktop.
mkdir -p "$HOME/.serena"
config="$HOME/.serena/serena_config.yml"
if [[ -f $config ]]; then
    sed -i -E \
        -e 's/^(web_dashboard):[[:space:]]*true/\1: false/' \
        -e 's/^(web_dashboard_open_on_launch):[[:space:]]*true/\1: false/' \
        "$config"
else
    cat >"$config" <<'EOF'
web_dashboard: false
web_dashboard_open_on_launch: false
EOF
fi

# Wrap uvx so the plugin's `uvx --from git+...oraios/serena serena start-mcp-server`
# call short-circuits to the already-installed binary. The real uvx is kept
# as uvx.real for all other invocations.
uvx_bin="$HOME/.local/bin/uvx"
uvx_real="$HOME/.local/bin/uvx.real"

if ! grep -q "oraios/serena" "$uvx_bin" 2>/dev/null; then
    [[ -e $uvx_real ]] || mv "$uvx_bin" "$uvx_real"
fi

cat >"$uvx_bin" <<'EOF'
#!/bin/bash
for arg in "$@"; do
    if [[ $arg == *"oraios/serena"* ]]; then
        exec serena-mcp-server
    fi
done
exec "$(dirname "$0")/uvx.real" "$@"
EOF
chmod +x "$uvx_bin"
