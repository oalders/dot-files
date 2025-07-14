#!/bin/bash

set -eu -o pipefail

# Create eza themes directory
mkdir -p ~/.config/eza/themes

# Download the Tokyo Night theme
curl -o ~/.config/eza/theme.yml \
    https://raw.githubusercontent.com/eza-community/eza-themes/main/themes/tokyonight.yml
