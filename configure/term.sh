#!/bin/bash

set -eu -o pipefail
TERMINFO_FILE="/tmp/${TERM}.ti"

# exit if this is already configured
infocmp -l -x | grep Smulx && exit

infocmp > $TERMINFO_FILE

sed -i '' '/smul=\\E\[4m,/a\
	Smulx=\\E\[4:%p1%dm,' "$TERMINFO_FILE"
if ! tic -x "$TERMINFO_FILE"; then
    echo "Error: Failed to compile terminfo file"
fi

rm -f "$TERMINFO_FILE"
