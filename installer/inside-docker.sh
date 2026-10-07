#!/usr/bin/env bash

set -eux
apt-get update && apt-get install -y --no-install-recommends ca-certificates git man sudo

# The bind-mounted repo is owned by the host user, not root.
git config --global --add safe.directory "$HOME/dot-files"
