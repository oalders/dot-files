# The fnm runtime-dir redirect (`NN_FNM_RUNTIME_DIR`)

Background for `NN_FNM_RUNTIME_DIR=$PWD/.tmp/run` in `bin/nn` and the fnm block
in `bashrc` (#1062).

## Why it's needed

`fnm env` creates a per-shell symlink under
`$XDG_RUNTIME_DIR/fnm_multishells/`, i.e. `/run/user/1000/fnm_multishells`.
The sandbox doesn't grant that path, so every sandboxed shell failed with
`Can't create the symlink: Permission denied`. fnm has no option of its own to
move it; it only follows `XDG_RUNTIME_DIR`.

## Why not grant `/run/user/1000/fnm_multishells`

Unsandboxed host shells' `PATH` runs through symlinks in that dir. Write access
from inside the sandbox could repoint them, which would be a sandbox escape.
`test/nono-profiles.bats` fails if any profile grants anything under
`/run/user`.

## Why not set `XDG_RUNTIME_DIR` for the whole session

Claude Code's messaging socket lives at `$XDG_RUNTIME_DIR/cc-socks/`, and
nono's `claude-code` base profile grants `/run/user/1000/cc-socks`. Moving
`XDG_RUNTIME_DIR` session-wide would put the socket outside that grant. So
bashrc applies the redirect to the `fnm env` call alone.
