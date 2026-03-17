# Dev Container Design

Date: 2026-03-11

## Goal

A single universal Docker image and a `bin/dev` launcher script that lets you
run Claude Code inside an isolated container from any project directory, across
any language, without adding files to each project.

## Prior Art

`~/Documents/github/oalders/my-mind-is-racing/Dockerfile.agent` and
`infra/scripts/agent-container.sh` solve this problem for one project. This
design generalizes that solution into dotfiles so it works everywhere.

## Image: `Dockerfile.dev`

Lives in `~/dot-files`. Built once locally (`dev build`), rebuilt when dotfiles
change.

### Base

`FROM ubuntu:latest` (replaces the mmir-specific CI base image).

### Contents

- apt deps: ca-certificates, git, man, sudo, wget, vim, ripgrep, perl,
  python3, locales, openssh-client, sqlite3, less, gh CLI
- dotfiles baked in via `dev-vm-install.sh` (run as non-root `agent` user)
- Node.js + TypeScript (explicitly installed, since these came from the mmir CI
  base image rather than dotfiles)
- Go tools: gopls, goimports, staticcheck, golangci-lint
- Playwright + Chromium (moved to `/opt/ms-playwright`, symlinked to standard
  paths so both Playwright and go-rod find it)
- All Claude plugins and MCP servers installed at image build time (not
  mounted from host)
- serena uvx cache pre-warmed so MCP server starts within Claude's connection
  timeout
- Non-root `agent` user with `AGENT_UID`/`AGENT_GID` build args matching host
  user (Claude refuses `--dangerously-skip-permissions` as root)

### Key env vars

```
PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
PLAYWRIGHT_MCP_SANDBOX=false
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
PATH=/home/agent/go/bin:/home/agent/local/bin:/home/agent/.local/bin:...
```

### Prerequisite: fix merge conflict

`dev-vm-install.sh` has an unresolved merge conflict (lines 21-28). Resolve it
before building — accept the "Stashed changes" side (comment out
`hashicorp/terraform` and `hetznercloud/cli`).

## Launcher: `bin/dev`

Lives in `~/dot-files/bin/`, symlinked into PATH via the existing symlinks
installer.

### Container naming

```
<repo-basename>-<branch>
```

Derived from:
```bash
REPO=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git rev-parse --abbrev-ref HEAD | tr '/' '-')
CONTAINER_NAME="${REPO}-${BRANCH}"
```

Branch names like `fix-123` and `gh-123` are unique per project. Combined with
the repo name, containers are unique across all projects and worktrees.

### Commands

```
dev build [--no-cache]   Build the dev-env image
dev start                Start container with workspace mounted
dev shell                Interactive bash shell in running container
dev claude [args...]     Run claude --dangerously-skip-permissions
dev reclaude [args...]   Stop and restart with claude
dev stop                 Stop and remove container
dev status               Show container status
```

### Volume mounts

The session isolation strategy is the core complexity. Claude stores sessions
keyed by the project path — but every container uses `/workspace`, so without
isolation all containers would share and clobber each other's sessions.

**Per-container host directory**: `~/.claude-containers/<container-name>/`

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.claude-containers/<name>/` | `/home/agent/.claude/projects/` | Session data, isolated per container |
| `~/.claude-containers/<name>/history.jsonl` | `/home/agent/.claude/history.jsonl` | Command history, isolated per container |
| `~/.claude.json` | `/home/agent/.claude.json` | Auth token (if present) |
| `~/.claude/.credentials.json` | `/home/agent/.claude/.credentials.json` | Auth credentials (if present) |
| `~/.claude/settings.json` | `/home/agent/.claude/settings.json` | User settings (if present) |
| `$(pwd)` | `/workspace` | Project files |

**Not mounted**: `~/.claude/plugins/` — plugins are baked into the image.
**Not mounted**: full `~/.claude/` — avoids clobbering plugin and MCP config
baked into the image.

### Git worktree support

If the workspace is a git worktree, the `.git` file contains an absolute path
back to the main repo's `.git` directory. Mount the main `.git` dir at the same
absolute path inside the container so git commands resolve correctly:

```bash
git_common_dir=$(git -C "$(pwd)" rev-parse --git-common-dir 2>/dev/null || true)
if [[ -n "$git_common_dir" && "$git_common_dir" != ".git" ]]; then
    git_common_dir=$(cd "$git_common_dir" && pwd)
    volume_flags+=(--volume "${git_common_dir}:${git_common_dir}")
fi
```

### Auth / env

- GitHub token: prefer `gh auth token`, fall back to `GITHUB_TOKEN` env var
- Pass `GH_TOKEN` and `GITHUB_TOKEN` into container
- `TINY_POSH=1` to suppress oh-my-posh decorations inside container
- Do NOT pass `ANTHROPIC_API_KEY` — Claude authenticates via the mounted
  `~/.claude.json` session token; passing an API key alongside causes a
  conflict

### Build

Passes dotfiles dir as a Docker build context (avoids a GitHub clone, always
uses local working copy):

```bash
docker build \
  -f ~/dot-files/Dockerfile.dev \
  -t dev-env:latest \
  --build-context dotfiles=~/dot-files \
  --secret id=github_token,env=GITHUB_TOKEN \
  --build-arg AGENT_UID=$(id -u) \
  --build-arg AGENT_GID=$(id -g) \
  ~/dot-files
```

## Session Resumption

Claude sessions can be resumed with `claude --resume <id>`. The session ID
appears in Claude's output. Because `~/.claude/projects/` and `history.jsonl`
are bind-mounted from the host at a per-container path, sessions persist across
container restarts and are resumable as long as you use the same container name
(i.e. same repo + branch).

To resume: `dev claude --resume <session-id>`

## What is NOT in scope

- Per-project customization (projects can still have their own `Dockerfile.agent`
  if needed, as mmir does)
- Publishing the image to a registry (local build only)
- Language version management via mise/asdf (languages are pinned in the image)
- TypeScript LSP beyond what the typescript-lsp plugin provides
