#!/bin/bash

set -eu -o pipefail

github_user="${1:-oalders}"

# SSH needs the directory itself locked down, not just the file.
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# -f makes curl fail on 404/5xx instead of piping an error page into our keys.
github_keys=$(curl -fsSL "https://github.com/${github_user}.keys")

# Add each key if it doesn't already exist
while IFS= read -r key; do
    [[ -n $key ]] || continue
    if grep -qxF "$key" ~/.ssh/authorized_keys; then
        echo "Key already exists: ${key:0:50}..."
    else
        echo "$key" >>~/.ssh/authorized_keys
        echo "Added key: ${key:0:50}..."
    fi
done <<<"$github_keys"

echo "Done! Total keys fetched: $(grep -c . <<<"$github_keys")"
