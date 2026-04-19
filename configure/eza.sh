#!/bin/bash

set -eu -o pipefail

# Create eza themes directory
mkdir -p ~/.config/eza/themes

# Download the Tokyo Night theme
# Pin to a specific commit to avoid pulling unexpected changes
curl -o ~/.config/eza/theme.yml \
    https://raw.githubusercontent.com/eza-community/eza-themes/add4c72c546992b8db674d6d3eea315bf2111b9a/themes/tokyonight.yml
