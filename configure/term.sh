#!/bin/bash

set -eu -o pipefail

if [ ! -v "$TERM" ]; then
  echo "TERM var does not exist. Is this CI?"
  exit 0
fi

TERMINFO_FILE="/tmp/${TERM}.ti"

# exit if this is already configured
infocmp -l -x | grep Smulx && exit

infocmp > $TERMINFO_FILE

if is os name eq darwin; then
sed -i '' '/smul=\\E\[4m,/a\
	Smulx=\\E\[4:%p1%dm,' "$TERMINFO_FILE"
else
sed -i '/smul=\\E\[4m,/a\
 	Smulx=\\E\[4:%p1%dm,' "$TERMINFO_FILE"
fi
if ! tic -x "$TERMINFO_FILE"; then
    echo "Error: Failed to compile terminfo file"
fi

rm -f "$TERMINFO_FILE"
