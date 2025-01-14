#!/bin/bash

set -eu -o pipefail

TERMINFO_FILE="/tmp/${TERM}.ti"

if [[ -f "$TERMINFO_FILE" ]]; then
    # Check if the Smulx line already exists to avoid duplicating it
    if ! grep -q 'Smulx=\\E\[4:%p1%dm,' "$TERMINFO_FILE"; then
        # Add the Smulx line after smul=\E[4m, if not already present
        sed -i '/smul=\\E\[4m,/a Smulx=\\E\[4:%p1%dm,' "$TERMINFO_FILE"
        echo "Smulx entry added to $TERMINFO_FILE."
        tic -x "$TERMINFO_FILE"
        echo "Terminfo updated and reloaded successfully."
    else
        echo "Smulx entry already present in $TERMINFO_FILE. No changes made."
    fi
else
    echo "Error: File $TERMINFO_FILE not found."
fi
