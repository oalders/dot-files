# The tmux control-socket grant (`unix_socket_dir`)

Background for `filesystem.unix_socket_dir: ["/tmp/tmux-1000"]` in
`oalders-core.json`.

## Why it's needed

Since nono 0.74.0 a sandboxed process cannot `connect()` to the tmux control
socket, so `tmux display-message` fails with `Permission denied` and any
best-effort session-name capture silently records an empty string. This is
intended nono behaviour, not a regression: the `--allow-unix-socket*` capability
family is byte-identical between 0.73.0 and 0.74.0, but 0.74.0 added fail-closed
inode-type validation to prepared Landlock rules, closing the hole where a broad
`/tmp` grant let the connect through. **Do not pin back to v0.73.0** — capture
worked there only because of the fail-open gap.

## Why `unix_socket_dir` specifically

It beats `unix_socket` on an exact path because the socket filename varies by
tmux server instance, and beats the `unix_socket_subtree*` and `*_bind` variants
because it grants `connect()` only — no `bind()`, no declared subtree. `nono why`
suggests `--allow-file`, which is neither sufficient nor necessary. Hardcoded to
UID 1000 like the `/tmp/claude-1000` entry; bump if the account's UID changes.

## Two caveats the key name undersells

1. **Recursive, not direct-children-only.** `nono profile schema` calls
   `unix_socket_dir` non-recursive, but `nono run --help` is more precise:
   *"Non-recursive on macOS and future Linux AF_UNIX mediation; current Linux
   Landlock filesystem fallback is recursive."* On this box the enforced grant is
   recursive over `/tmp/tmux-1000` — harmless today (the dir is `drwx------`, uid
   1000, flat socket files only) but it would silently swallow any subdirectory a
   future tool colocates there.
2. **Implies directory read.** A sandboxed process can also *list*
   `/tmp/tmux-1000` and enumerate socket filenames for every tmux server under
   this UID.

## Security tradeoff, accepted deliberately (#1022)

This grant is not scoped to reading a session name. A process holding the tmux
socket can also `tmux send-keys` into any pane on that server, including panes
running unsandboxed shells — a sandbox escape. It lives in `oalders-core`, so
every sandboxed session inherits it. Accepted on the grounds that the panes in
question are our own; revisit by moving it to a narrow opt-in sibling profile if
that stops being true.
