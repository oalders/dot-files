#!/bin/bash

set -eu -o pipefail

# Install Claude Code plugin marketplaces and plugins.
# Called from Dockerfile.dev and can be run standalone to sync plugins.

claude plugin marketplace add obra/superpowers-marketplace
claude plugin marketplace add anthropics/claude-code
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add oalders/talk-about-us
claude plugin marketplace add oalders/kitchen-sink

claude plugin install superpowers@superpowers-marketplace
claude plugin install superpowers-chrome@superpowers-marketplace
claude plugin install superpowers-lab@superpowers-marketplace
claude plugin install elements-of-style@superpowers-marketplace
claude plugin install superpowers-developing-for-claude-code@superpowers-marketplace
claude plugin install code-review@claude-code-plugins
claude plugin install frontend-design@claude-code-plugins
claude plugin install pr-review-toolkit@claude-code-plugins
claude plugin install commit-commands@claude-code-plugins
claude plugin install serena@claude-plugins-official
claude plugin install gopls-lsp@claude-plugins-official
claude plugin install typescript-lsp@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install playwright@claude-plugins-official
claude plugin install talk-about-us@talk-about-us
claude plugin install kitchen-sink@kitchen-sink
