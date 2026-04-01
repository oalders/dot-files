#!/bin/bash

set -euxo pipefail

if ! is there claude; then
    curl -fsSL https://claude.ai/install.sh | bash
else
    claude install
fi

if ! is there uv; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

export PATH="$HOME/.local/bin:$PATH"

if ! is there serena; then
    uv tool install git+https://github.com/oraios/serena@v0.1.4
fi
