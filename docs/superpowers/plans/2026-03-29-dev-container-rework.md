# Dev Container Rework Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework `bin/dev` to use token-based auth, Docker named volumes, and inline firewall — eliminating host credential mounts.

**Architecture:** Modify `bin/dev` in-place and `Dockerfile.dev` minimally. Auth via `CLAUDE_CODE_OAUTH_TOKEN` env var. Sessions persist in Docker named volumes scoped per repo+branch. Firewall runs inline before Claude only.

**Tech Stack:** Bash, Docker, iptables/ipset

**Spec:** `docs/superpowers/specs/2026-03-29-dev-container-rework-design.md`

---

## Chunk 1: Dockerfile changes

### Task 1: Add iptables and ipset to Dockerfile.dev

**Files:**
- Modify: `Dockerfile.dev:9-26`

- [ ] **Step 1: Add packages to the system dependencies block**

In `Dockerfile.dev`, add `iptables` and `ipset` to the existing `apt-get install` on lines 9-23:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    iptables \
    ipset \
    jq \
    less \
    locales \
    man-db \
    openssh-client \
    perl \
    python3 \
    ripgrep \
    sqlite3 \
    sudo \
    vim \
    wget && \
    sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && \
    locale-gen && \
    printf 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8\n' > /etc/default/locale
```

- [ ] **Step 2: Install claude-firewall.sh into the image**

The firewall script lives at `bin/claude-firewall.sh` in the dotfiles repo, which
is already copied into the image via `COPY --from=dotfiles`. Add a symlink step
after the dotfiles install in `Dockerfile.dev`, after the `USER agent` line (line 103):

Add this `RUN` instruction after the existing `USER agent` line but before the
Go dev tools block:

```dockerfile
# Firewall script for restricting container network access
RUN sudo ln -s /home/agent/dot-files/bin/claude-firewall.sh /usr/local/bin/claude-firewall.sh
```

- [ ] **Step 3: Commit**

```bash
git add Dockerfile.dev
git commit -m "feat(dev): add iptables, ipset, jq and firewall script to image"
```

### Task 2: Bake settings.json into the image

The named volume will mount over `/home/agent/.claude`, shadowing baked-in files.
We solve this by baking settings into the dotfiles directory (which is already
copied into the image) and having the init script copy them into place at first
run.

**Files:**
- Create: `claude/settings.json` (canonical settings to bake into image)
- Create: `claude/init-claude-dir.sh` (seeds settings into named volume)

- [ ] **Step 1: Check what settings.json currently contains on host**

Run: `cat ~/.claude/settings.json` (on host) to see what settings are in use.
This informs what to bake into the image.

- [ ] **Step 2: Create claude/settings.json**

Create `claude/settings.json` in the repo with the desired default settings.
This file will be copied into the image during build.

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(gh *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(go *)",
      "Bash(make *)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep"
    ],
    "deny": []
  }
}
```

Adjust based on Step 1 output. The key point: this is the canonical set of
permissions for the container environment.

- [ ] **Step 3: Add init script that copies baked settings on first run**

Create `claude/init-claude-dir.sh`:

```bash
#!/usr/bin/env bash
# Initialize /home/agent/.claude from baked-in defaults if empty.
# Called at container start before any Claude commands.
# The named volume mounts over /home/agent/.claude, so baked-in files
# are shadowed. This script copies them into the volume on first run.

set -euo pipefail

CLAUDE_DIR="/home/agent/.claude"
BAKED_DIR="/home/agent/dot-files/claude"

# Only copy if settings.json doesn't exist yet (first run)
if [[ ! -f "${CLAUDE_DIR}/settings.json" ]]; then
    mkdir -p "${CLAUDE_DIR}"
    cp "${BAKED_DIR}/settings.json" "${CLAUDE_DIR}/settings.json"
    echo "Initialized ${CLAUDE_DIR}/settings.json from image defaults"
fi
```

- [ ] **Step 4: Commit**

```bash
git add claude/settings.json claude/init-claude-dir.sh
git commit -m "feat(dev): add baked-in settings.json and init script"
```

---

## Chunk 2: Auth changes in bin/dev

### Task 3: Replace credential mounts with CLAUDE_CODE_OAUTH_TOKEN

**Files:**
- Modify: `bin/dev:40-64` (build_env_flags function)
- Modify: `bin/dev:119-140` (container_start volume_flags)

- [ ] **Step 1: Add token resolution to build_env_flags**

Replace the comment block about ANTHROPIC_API_KEY (lines 43-45) and add token
resolution. The full updated `build_env_flags` function:

```bash
build_env_flags() {
    local -n _flags=$1

    # Claude auth: CLAUDE_CODE_OAUTH_TOKEN env var or ~/.claude-token file
    local claude_token="${CLAUDE_CODE_OAUTH_TOKEN:-}"
    if [[ -z "$claude_token" && -f "${HOME}/.claude-token" ]]; then
        claude_token="$(cat "${HOME}/.claude-token")"
    fi
    if [[ -n "$claude_token" ]]; then
        _flags+=(-e "CLAUDE_CODE_OAUTH_TOKEN=${claude_token}")
    else
        error "No Claude token found. Set CLAUDE_CODE_OAUTH_TOKEN env var or save token to ~/.claude-token (generate with: claude setup-token)"
    fi

    # GitHub token: prefer gh auth token, fall back to GITHUB_TOKEN env var
    local gh_token=""
    if command -v gh >/dev/null 2>&1; then
        gh_token=$(gh auth token 2>/dev/null || true)
    fi
    if [[ -z "$gh_token" ]]; then
        gh_token="${GITHUB_TOKEN:-}"
    fi
    if [[ -n "$gh_token" ]]; then
        _flags+=(-e "GH_TOKEN=${gh_token}")
        _flags+=(-e "GITHUB_TOKEN=${gh_token}")
    else
        warn "No GitHub token found - gh CLI will be unauthenticated"
    fi

    # Suppress oh-my-posh decorations inside container
    _flags+=(-e "TINY_POSH=1")
}
```

- [ ] **Step 2: Verify the script still parses**

Run: `bash -n bin/dev`
Expected: no output (clean parse)

- [ ] **Step 3: Commit**

```bash
git add bin/dev
git commit -m "feat(dev): add CLAUDE_CODE_OAUTH_TOKEN resolution to build_env_flags"
```

### Task 4: Remove credential file mounts from container_start

**Files:**
- Modify: `bin/dev:119-150` (container_start function)

- [ ] **Step 1: Remove host credential mounts and host dir creation**

Remove these lines from `container_start`:

```bash
# Remove these:
mkdir -p "${BRANCH_CLAUDE_DIR}"
touch "${BRANCH_CLAUDE_DIR}/history.jsonl"

# Remove these volume flags:
--volume "${BRANCH_CLAUDE_DIR}:/home/agent/.claude/projects"
--volume "${BRANCH_CLAUDE_DIR}/history.jsonl:/home/agent/.claude/history.jsonl"

# Remove these conditional mounts:
[[ -f "${HOME}/.claude.json" ]] && \
    volume_flags+=(--volume "${HOME}/.claude.json:/home/agent/.claude.json")
[[ -f "${HOST_CLAUDE_DIR}/.credentials.json" ]] && \
    volume_flags+=(--volume "${HOST_CLAUDE_DIR}/.credentials.json:/home/agent/.claude/.credentials.json")
[[ -f "${HOST_CLAUDE_DIR}/settings.json" ]] && \
    volume_flags+=(--volume "${HOST_CLAUDE_DIR}/settings.json:/home/agent/.claude/settings.json")
```

- [ ] **Step 2: Verify the script still parses**

Run: `bash -n bin/dev`
Expected: no output (clean parse)

- [ ] **Step 3: Commit**

```bash
git add bin/dev
git commit -m "feat(dev): remove host credential and session dir mounts"
```

---

## Chunk 3: Named volume support

### Task 5: Add Docker named volume for sessions

**Files:**
- Modify: `bin/dev` (container_start function, top-level variables)

- [ ] **Step 1: Add volume name variable at top of script**

After line 23 (`CONTAINER_NAME`), replace `BRANCH_CLAUDE_DIR` with:

```bash
VOLUME_NAME="dev-${REPO}-${BRANCH}-sessions"
```

Remove the `BRANCH_CLAUDE_DIR` line (line 24) and `HOST_CLAUDE_DIR` (line 18)
since they are no longer used.

- [ ] **Step 2: Replace bind mounts with named volume in container_start**

The volume_flags in `container_start` become:

```bash
    local volume_flags=(
        --volume "$(pwd):/workspace"
        --volume "${VOLUME_NAME}:/home/agent/.claude"
    )
```

Keep the git worktree mount unchanged (lines 142-149).

- [ ] **Step 3: Run init script at container start**

After `docker run`, execute the init script to seed settings into the volume:

```bash
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --hostname dev-agent \
        --add-host host.docker.internal:host-gateway \
        --cap-add=NET_ADMIN \
        "${volume_flags[@]}" \
        --workdir /workspace \
        "${env_flags[@]}" \
        "${IMAGE_NAME}" \
        sleep infinity

    # Seed baked-in settings into the named volume on first run
    docker exec "${CONTAINER_NAME}" bash /home/agent/dot-files/claude/init-claude-dir.sh
```

Note `--cap-add=NET_ADMIN` is added here for firewall support.

- [ ] **Step 4: Verify the script still parses**

Run: `bash -n bin/dev`
Expected: no output (clean parse)

- [ ] **Step 5: Commit**

```bash
git add bin/dev
git commit -m "feat(dev): use Docker named volume for session persistence"
```

---

## Chunk 4: Firewall integration and new commands

### Task 6: Add firewall to dev claude command

**Files:**
- Modify: `bin/dev` (container_claude function)

- [ ] **Step 1: Run firewall before Claude in container_claude**

Replace the current `container_claude` function:

```bash
container_claude() {
    check_requirements
    _ensure_running

    info "Enabling firewall and starting Claude Code..."
    docker exec -it "${CONTAINER_NAME}" bash -l -c \
        "sudo /usr/local/bin/claude-firewall.sh && claude --dangerously-skip-permissions $(printf '%q ' "$@")" || true
    info "Claude session ended. Container still running. Use 'dev stop' to remove."
}
```

Note: `claude-firewall.sh` requires root for iptables, so we use `sudo`. The
agent user has passwordless sudo configured in the Dockerfile.

- [ ] **Step 2: Verify the script still parses**

Run: `bash -n bin/dev`
Expected: no output (clean parse)

- [ ] **Step 3: Commit**

```bash
git add bin/dev
git commit -m "feat(dev): run firewall before Claude in dev claude"
```

### Task 7: Add dev clean and dev clean --all commands

**Files:**
- Modify: `bin/dev` (add container_clean function, update case statement and usage)

- [ ] **Step 1: Add container_clean function**

Add before the `case` statement:

```bash
container_clean() {
    check_requirements

    if [[ "${1:-}" == "--all" ]]; then
        info "Removing all dev session volumes..."
        # Stop any containers using dev volumes first
        local containers
        containers=$(docker ps -a --filter "name=^dev-" --format '{{.Names}}' || true)
        if [[ -n "$containers" ]]; then
            echo "$containers" | while read -r ctr; do
                docker rm -f "$ctr" >/dev/null 2>&1 || true
            done
            info "Removed associated containers"
        fi
        local volumes
        volumes=$(docker volume ls --format '{{.Name}}' | grep '^dev-.*-sessions$' || true)
        if [[ -z "$volumes" ]]; then
            info "No dev session volumes found"
            return 0
        fi
        echo "$volumes" | while read -r vol; do
            docker volume rm "$vol" >/dev/null
            info "Removed volume: $vol"
        done
    else
        # Stop container if running (volume can't be removed while in use)
        container_stop 2>/dev/null || true
        if docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1; then
            docker volume rm "${VOLUME_NAME}" >/dev/null
            info "Removed session volume: ${VOLUME_NAME}"
        else
            info "No session volume '${VOLUME_NAME}' found"
        fi
    fi
}
```

- [ ] **Step 2: Update case statement**

Add `clean` to the case statement:

```bash
case "${1:-}" in
    build)   shift; container_build "$@" ;;
    start)   container_start ;;
    shell)   container_shell ;;
    claude)  shift; container_claude "$@" ;;
    reclaude) shift; container_stop; container_claude "$@" ;;
    stop)    container_stop ;;
    clean)   shift; container_clean "$@" ;;
    status)  container_status ;;
    *)
```

- [ ] **Step 3: Update usage text**

Update both the usage in the `*` case and the header comments to include `clean`:

```bash
        echo "Usage: dev {build|start|shell|claude|reclaude|stop|clean|status}"
        echo ""
        echo "Commands:"
        echo "  build [--no-cache]   Build the dev-env image"
        echo "  start                Start container with workspace mounted"
        echo "  shell                Interactive bash shell in container"
        echo "  claude [args...]     Run claude with firewall enabled"
        echo "  reclaude [args...]   Stop and restart with claude"
        echo "  stop                 Stop and remove container"
        echo "  clean [--all]        Remove session volume(s)"
        echo "  status               Show container status"
```

Also update the header comment at the top of the file to match.

- [ ] **Step 4: Verify the script still parses**

Run: `bash -n bin/dev`
Expected: no output (clean parse)

- [ ] **Step 5: Commit**

```bash
git add bin/dev
git commit -m "feat(dev): add dev clean and dev clean --all commands"
```

### Task 8: Update container_stop and container_status

**Files:**
- Modify: `bin/dev` (container_stop and container_status functions)

- [ ] **Step 1: Update container_stop**

Remove the reference to `BRANCH_CLAUDE_DIR`. The function should no longer print
"Session history preserved at..." since sessions are in a Docker volume now:

```bash
container_stop() {
    check_requirements

    local is_running is_stopped
    is_running=$(docker ps    --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}')
    is_stopped=$(docker ps -a --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}')

    if [[ -z "$is_stopped" ]]; then
        info "Container '${CONTAINER_NAME}' does not exist"
        return 0
    fi

    if [[ -n "$is_running" ]]; then
        info "Stopping container '${CONTAINER_NAME}'..."
        docker stop "${CONTAINER_NAME}" >/dev/null
    fi
    docker rm "${CONTAINER_NAME}" >/dev/null
    info "Container '${CONTAINER_NAME}' removed (session volume '${VOLUME_NAME}' preserved)"
}
```

- [ ] **Step 2: Update container_status**

Replace the session dir check at the end with a volume check:

```bash
    echo ""
    if docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1; then
        echo -e "Session vol: ${GREEN}exists${NC} (${VOLUME_NAME})"
    else
        echo -e "Session vol: ${YELLOW}not created yet${NC}"
    fi
    echo ""
```

Also update the "Sessions:" line in the usage `*` case:

```bash
        echo "Sessions:  Docker volume ${VOLUME_NAME}"
```

- [ ] **Step 3: Verify the script still parses**

Run: `bash -n bin/dev`
Expected: no output (clean parse)

- [ ] **Step 4: Commit**

```bash
git add bin/dev
git commit -m "feat(dev): update stop/status for named volume sessions"
```

---

## Chunk 5: Verify end-to-end

### Task 9: Manual smoke test

- [ ] **Step 1: Generate token**

Run on host: `claude setup-token`
Save the output to `~/.claude-token`.

- [ ] **Step 2: Build the image**

Run: `dev build`
Expected: Image builds successfully with iptables/ipset packages.

- [ ] **Step 3: Start container**

Run: `dev start`
Expected: Container starts, init script runs, volume created.

- [ ] **Step 4: Test shell access**

Run: `dev shell`
Expected: Interactive shell, no firewall restrictions.
Verify: `curl https://example.com` should succeed.

- [ ] **Step 5: Test Claude with firewall**

Run: `dev claude`
Expected: Firewall configures, Claude starts with token auth.
Verify: Inside Claude, network is restricted to whitelisted domains.

- [ ] **Step 6: Test volume persistence**

Run: `dev stop` then `dev start` then `dev shell`
Verify: `ls /home/agent/.claude/` shows previous session data.

- [ ] **Step 7: Test clean commands**

Run: `dev clean`
Expected: Volume for current project removed.

Run: `dev status`
Expected: Shows "Session vol: not created yet"

- [ ] **Step 8: Commit any fixes from smoke testing**

```bash
git add -u
git commit -m "fix(dev): fixes from smoke testing"
```
