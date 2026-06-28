# Global instructions

## Temp files

When creating temporary files or directories, default to `$TMPDIR` if it is set
in the environment, falling back to `/tmp` only when it is unset. Do not
hardcode `/tmp`. This applies to `mktemp`, scratch files, test fixtures, and
anything else that lands in a temp location.

## Playwright browser cache is read-only in the nono sandbox

`~/.cache/ms-playwright` is mounted **read-only** inside the nono sandbox on
purpose: it is a single host browser bundle shared across every worktree and
the Playwright MCP, so sessions may execute the browsers but must never write
them (writes would poison the bundle for the host and for other sessions).

If a sandboxed Playwright run fails with a write/permission error on
`~/.cache/ms-playwright` (typically during `playwright install` or a browser
download), do **not** try to work around it — not with `nono run --allow`, not
by editing the nono profile to make the path writable. The error means the host
bundle is missing the browser build this run needs (usually a Playwright
version bump). The fix runs on the host, **outside** the sandbox: tell the user
to run `installer/playwright-mcp.sh` (it runs `npx playwright install`) to
refresh the bundle, then re-run. Normal test runs against an already-seeded
browser work read-only and need no change.
