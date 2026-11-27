#!/usr/bin/env bash

set -eu -o pipefail

prefs="$HOME/Library/Application Support/Spotify/prefs"

if [[ ! -f $prefs ]] || grep -q '^app.autostart-mode="off"$' "$prefs"; then
    exit 0
fi

# Spotify rewrites prefs on quit, so an edit made while it runs is lost
if pgrep -x Spotify >/dev/null; then
    echo "Quit Spotify and re-run $0 to disable its launch at login"
    exit 0
fi

# prefs holds Spotify's saved login token; keep the rewrite owner-only
(umask 077 && grep -v '^app.autostart-mode=' "$prefs" >"$prefs.new") || true
echo 'app.autostart-mode="off"' >>"$prefs.new"
mv "$prefs.new" "$prefs"
