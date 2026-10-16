# gh wrapper: private-to-public guard

`bin/gh` refuses, inside a Claude session, any write that would carry content
from a private context to a non-private repository. The threat is accidents
(an embargoed CVE posted as a public issue, or a fix branch pushed upstream),
not a hostile agent.

## Rule

- The session is private if any GitHub remote of cwd's repo, or of
  `$NN_SESSION_DIR`'s repo (exported by `bin/nn`), is not public. A failed
  lookup counts as private.
- In a private session, every target of a write must be `private`, `internal`,
  or listed in `~/.config/gh/wrapper-allow-public` (one `owner/repo` per line,
  `#` comments). Unknown targets and failed lookups are refused.
- Without `-R` or a URL, the targets are `$GH_REPO`, else every GitHub remote
  of cwd plus any `gh repo set-default` choice. gh would pick one, preferring
  `upstream`, so a private repo with a public `upstream` remote is exactly the
  risky setup; there the agent must pass `-R`.

## Overrides

The allowlist is the only override. Nono mounts `~/.config/gh` read-only, so
the agent can't add to it. There is no env-var escape hatch: an agent that hits
a block would set it.

## Covered

issue/pr/release writes, `issue transfer`, `release upload`, gists, `gh api`
REST writes, GraphQL mutations (judged by cwd's repo), and `git push` under
`nn` (via `gh auth git-credential` with `credential.useHttpPath`; git only
asks for credentials after a 401, so public fetches never reach it).

## Not covered

- A session in a repo with no GitHub remote (or none yet) is unrestricted.
- GraphQL mutations name their target only by node ID; they are judged by
  cwd's repo, so a mutation aimed at a public repo from a private checkout
  passes.
- Making a repo public (`repo edit --visibility`, `gh api -X PATCH
  repos/o/r`): deliberate, not an accident.
- Content-carrying subcommands the wrapper doesn't classify:
  `workflow run -f`, `repo edit --description`, `project item-create`,
  labels, and the like.
- Calling `/usr/bin/gh` directly, `curl` with a token, or `gh auth token`.
- Hosts other than github.com.

Visibility comes from the real `gh` at write time, a few API calls per write.
