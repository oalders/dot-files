# Why `network_profile` is set to `null`

Background for the `"network_profile": null` in `oalders-net.json`.

## The problem

The `claude-code` network bundle (`network.network_profile`) sets up nono's
reverse proxy and injects `ANTHROPIC_BASE_URL=http://127.0.0.1:<port>/anthropic`.
The `anthropic` route demands `env://ANTHROPIC_API_KEY`; Max/OAuth users have no
API key, so the proxy returns `407 Proxy Authentication Required`. The startup
`WARN ... requests will proceed without credential injection` is misleading — the
actual behavior is hard-reject.

Surfaced 2026-04-30 after claude auto-updated to a version that respects
`ANTHROPIC_BASE_URL`. Earlier claude went to `api.anthropic.com` directly and
tunneled through `HTTPS_PROXY`, dodging the intercept.

## The workaround

Set `"network_profile": null` in `oalders-net.json` (where all outbound rules
now live) and replace the curated bundle with an explicit `allow_domain` list
(Anthropic, GitHub, npm, Go module proxy). The explicit `null` is the documented
opt-out pattern — see nono's `docs/cli/clients/claude-code.mdx`
(`claude-code-netopen` example). Today the parent `claude-code` profile doesn't
set `network_profile`, so omitting the field would also work, but `null` is
defensive against a future nono release adding it back.

While `network_profile` is null, the `NO_PROXY` reset in `bin/nn` is vestigial
(no proxy is started) but harmless — it re-becomes load-bearing the moment the
curated bundle is restored.

## OAuth auth hosts must stay in `allow_domain`

Once `network_profile` is null, nono's proxy is default-deny, so the
`allow_domain` list must include every host Claude's OAuth flow touches — not
just `api.anthropic.com`. Claude Code 2.1.x refreshes the token at
`POST https://platform.claude.com/v1/oauth/token` (authorize on
`platform.claude.com` / `claude.com`). `*.claude.com` + `claude.com` cover this.

If they are missing, the running sandbox can't refresh: the access token expires
(~6–8h), the session shows "logged out" while a still-valid refresh token sits on
disk, and opening host-Claude (full outbound) refreshes and heals the sandbox via
`~/.claude/.credentials.json` with no restart. The allowlist predated the move off
`console.anthropic.com` / `claude.ai`, so a Claude upgrade silently relocated the
auth host. On each Claude upgrade, re-check the endpoint and keep it allowed:

```sh
strings ~/.local/share/claude/versions/* | grep -oE 'https://[a-z.]+/v1/oauth/token' | sort -u
```

## Upstream to watch

- <https://github.com/always-further/nono/issues/793> — exec-sourced credentials
  (covers `apiKeyHelper` shape)
- <https://github.com/always-further/nono/issues/770> — refreshable credential
  backend
- <https://github.com/always-further/nono/issues/724> — 3rd-party provider
  profiles

## Re-test on each nono release

Temporarily flip `"network_profile": null` to `"claude-code"` in
`oalders-net.json` and run from `$TMPDIR`:

```sh
cd "${TMPDIR:-/tmp}" && nono run --profile oalders --allow-cwd -- curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST "$ANTHROPIC_BASE_URL/v1/messages" -d '{}'
```

Non-407 means the route became OAuth-aware and you can re-adopt the curated
bundle.
