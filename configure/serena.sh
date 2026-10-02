#!/bin/bash

set -eu -o pipefail

# Edit ~/.serena/serena_config.yml in place rather than symlinking it: serena
# rewrites this file on load (it regenerates the private auth_secret and the
# machine-local projects list), and this repo is public, so the file must never
# live here. Keep the host dashboard enabled but unobtrusive:
#   * web_dashboard_interface: browser -> no system-tray / menu-bar icon.
#   * web_dashboard_open_on_launch: false -> no browser tab spawned per launch
#     (also what kept MCP handshakes from hanging in headless environments).
# Still reachable at http://localhost:24282/dashboard/ (port climbs if taken).
# The sandbox dashboard is governed separately by nono/serena_config.yml.

config="$HOME/.serena/serena_config.yml"
mkdir -p "$(dirname "$config")"

if [[ -f $config ]]; then
    # -i.bak for BSD/GNU sed portability (this runs on the macOS host too).
    sed -i.bak -E \
        -e 's/^(web_dashboard):.*/\1: true/' \
        -e 's/^(web_dashboard_open_on_launch):.*/\1: false/' \
        -e 's/^(web_dashboard_interface):.*/\1: browser/' \
        "$config"
    rm -f "$config.bak"
else
    cat >"$config" <<'EOF'
web_dashboard: true
web_dashboard_open_on_launch: false
web_dashboard_interface: browser
EOF
fi
