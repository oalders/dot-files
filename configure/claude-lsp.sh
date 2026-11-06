#!/bin/bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh
add_path "$HOME/.local/bin"

claude plugin marketplace add ~/dot-files/claude-plugins
claude plugin install bash-perl-lsp@dot-files

# Serena was removed in #1099; undo what installer/serena-mcp.sh and
# configure/claude.sh set up on existing hosts.
if claude plugin list --json | jq -e 'any(.[]; .id == "serena@claude-plugins-official" and .scope == "user")' >/dev/null; then
    claude plugin uninstall serena@claude-plugins-official
fi

if claude mcp get serena >/dev/null 2>&1; then
    claude mcp remove -s user serena
fi

uvx="$HOME/.local/bin/uvx"
if [[ -e $uvx.real ]]; then
    if [[ ! -e $uvx ]] || grep -q "oraios/serena" "$uvx"; then
        mv "$uvx.real" "$uvx"
    else
        rm -f "$uvx.real"
    fi
fi
