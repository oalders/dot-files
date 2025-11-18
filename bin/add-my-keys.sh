#!/bin/bash

set -eu -o pipefail

# Create authorized_keys if it doesn't exist
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Fetch GitHub keys
github_keys=$(curl -s https://github.com/oalders.keys)

# Add each key if it doesn't already exist
while IFS= read -r key; do
    if [[ -n "$key" ]]; then
        if ! grep -qF "$key" ~/.ssh/authorized_keys; then
            echo "$key" >> ~/.ssh/authorized_keys
            echo "Added key: ${key:0:50}..."
        else
            echo "Key already exists: ${key:0:50}..."
        fi
    fi
done <<< "$github_keys"

echo "Done! Total keys in authorized_keys: $(wc -l < ~/.ssh/authorized_keys)"
