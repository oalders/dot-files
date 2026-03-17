# Dev Container Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** A universal Docker image and `bin/dev` launcher that runs Claude Code in isolated containers from any project directory.

**Architecture:** Port `my-mind-is-racing`'s `Dockerfile.agent` + `agent-container.sh` into dotfiles as `Dockerfile.dev` + `bin/dev`. Replace the mmir-specific CI base image with `ubuntu:latest` and install Node.js/Playwright explicitly. Remove all mmir-specific env vars and container naming.

**Tech Stack:** Docker (BuildKit), Bash, Ubuntu base image, Node.js 24.x, Playwright, Go tools

**Spec:** `docs/superpowers/specs/2026-03-11-dev-container-design.md`
**Prior art:** `~/Documents/github/oalders/my-mind-is-racing/Dockerfile.agent` and `infra/scripts/agent-container.sh`

---

### Task 1: Create Dockerfile.dev

**Files:**
- Create: `Dockerfile.dev`

**Step 1: Write the Dockerfile**

Port `my-mind-is-racing/Dockerfile.agent` with these changes:
- Base: `FROM ubuntu:latest` instead of the mmir CI image
- Add Node.js 24.x installation (nodesource pattern from `installer/npm.sh`)
- Add Playwright + Chromium installation (since it no longer comes from CI base)
- Add Go installation (no longer from CI base)
- Keep: non-root `agent` user, dotfiles copy via build context, BuildKit secrets
- Keep: Go tools (gopls, goimports, golangci-lint), serena uvx cache, Claude plugins
- Keep: Playwright browser relocation + symlinks, locale setup
- Remove: `trurl` backports install (Debian-specific, not needed on Ubuntu)
- Remove: `mmir-cache` mount

```dockerfile
# Universal dev container for running Claude Code in isolation.
# Build:  dev build
# Run:    dev claude
# Shell:  dev shell

FROM ubuntu:latest

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
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

# Node.js 24.x (needed for Claude plugins, TypeScript LSP, npm packages)
RUN curl -sL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs

# Go (needed for gopls, goimports, golangci-lint)
RUN curl -sL https://go.dev/dl/go1.24.1.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# Playwright + Chromium
# Install Playwright CLI, then install Chromium browser, then move to shared location
RUN npx --yes playwright install --with-deps chromium && \
    mv /root/.cache/ms-playwright /opt/ms-playwright && \
    mkdir -p /opt/google/chrome && \
    ln -s /opt/ms-playwright/chromium-*/chrome-linux64/chrome /opt/google/chrome/chrome && \
    ln -s /opt/ms-playwright/chromium-*/chrome-linux64/chrome /usr/local/bin/chromium && \
    ln -s /opt/ms-playwright/chromium-*/chrome-linux64/chrome /usr/local/bin/chrome && \
    ln -s /opt/ms-playwright/chromium-*/chrome-linux64/chrome /usr/local/bin/google-chrome && \
    ln -s /opt/ms-playwright/chromium-*/chrome-linux64/chrome /usr/bin/google-chrome && \
    ln -s /opt/ms-playwright/chromium-*/chrome-linux64/chrome /usr/bin/chromium-browser && \
    ln -s /opt/ms-playwright/chromium-*/chrome-linux64/chrome /usr/bin/chromium
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
ENV PLAYWRIGHT_MCP_SANDBOX=false

# Non-root user matching host UID/GID
ARG AGENT_UID=1000
ARG AGENT_GID=1000
RUN groupadd -g "${AGENT_GID}" agent && \
    useradd -m -u "${AGENT_UID}" -g "${AGENT_GID}" -s /bin/bash agent && \
    echo "agent ALL=(ALL) NOPASSWD:SETENV:ALL" >> /etc/sudoers

# Ensure ~/.local/bin is always in PATH for login shells
RUN echo 'export PATH="${HOME}/.local/bin:${HOME}/local/bin:${PATH}"' \
    > /etc/profile.d/local-bin.sh

# Copy dotfiles from host (--build-context dotfiles=~/dot-files)
COPY --from=dotfiles . /home/agent/dot-files
RUN --mount=type=secret,id=github_token \
    chown -R agent:agent /home/agent/dot-files && \
    chown -R agent:agent /opt/ms-playwright && \
    rm -f /home/agent/.bashrc /home/agent/.bash_profile /home/agent/.profile && \
    cd /home/agent/dot-files && \
    export GH_TOKEN="$(cat /run/secrets/github_token 2>/dev/null)" && \
    sudo -u agent \
        GH_TOKEN="$GH_TOKEN" \
        GITHUB_TOKEN="$GH_TOKEN" \
        DEBIAN_FRONTEND=noninteractive \
        HOME=/home/agent \
        bash dev-vm-install.sh

USER agent

# Go dev tools (gopls for Serena, goimports for precious, golangci-lint for linting)
RUN GOTOOLCHAIN=auto GOPATH=/home/agent/go /usr/local/go/bin/go install golang.org/x/tools/gopls@latest && \
    GOTOOLCHAIN=auto GOPATH=/home/agent/go /usr/local/go/bin/go install golang.org/x/tools/cmd/goimports@latest && \
    GOTOOLCHAIN=auto CGO_ENABLED=0 GOPATH=/home/agent/go /usr/local/go/bin/go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest && \
    npm install --prefix /home/agent/.local -g cc-pulse

# Pre-warm Serena uvx cache (avoids timeout on first MCP connection)
RUN /home/agent/.local/bin/uvx --from git+https://github.com/oraios/serena serena --help || true

# Claude Code marketplaces and plugins (baked into image, not mounted from host)
RUN --mount=type=secret,id=github_token \
    export GH_TOKEN="$(cat /run/secrets/github_token 2>/dev/null)" && \
    export HOME=/home/agent && \
    export PATH="/home/agent/local/bin:/home/agent/.local/bin:${PATH}" && \
    claude plugin marketplace add obra/superpowers-marketplace && \
    claude plugin marketplace add anthropics/claude-code && \
    claude plugin marketplace add anthropics/claude-plugins-official && \
    claude plugin marketplace add oalders/talk-about-us && \
    claude plugin marketplace add oalders/kitchen-sink && \
    claude plugin install superpowers@superpowers-marketplace && \
    claude plugin install superpowers-chrome@superpowers-marketplace && \
    claude plugin install superpowers-lab@superpowers-marketplace && \
    claude plugin install elements-of-style@superpowers-marketplace && \
    claude plugin install superpowers-developing-for-claude-code@superpowers-marketplace && \
    claude plugin install code-review@claude-code-plugins && \
    claude plugin install frontend-design@claude-code-plugins && \
    claude plugin install pr-review-toolkit@claude-code-plugins && \
    claude plugin install commit-commands@claude-code-plugins && \
    claude plugin install serena@claude-plugins-official && \
    claude plugin install gopls-lsp@claude-plugins-official && \
    claude plugin install typescript-lsp@claude-plugins-official && \
    claude plugin install frontend-design@claude-plugins-official && \
    claude plugin install playwright@claude-plugins-official && \
    claude plugin install talk-about-us@talk-about-us && \
    claude plugin install kitchen-sink@kitchen-sink

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV PATH="/home/agent/go/bin:/home/agent/local/bin:/home/agent/.local/bin:${PATH}"
WORKDIR /workspace
```

**Step 2: Verify Dockerfile syntax**

Run: `docker build --check -f ~/dot-files/Dockerfile.dev ~/dot-files 2>&1 | head -5`
Expected: No syntax errors (or "unknown flag" if Docker version doesn't support --check, which is fine)

**Step 3: Commit**

```bash
git add Dockerfile.dev
git commit -m "feat: add Dockerfile.dev for universal dev container"
```

---

### Task 2: Create bin/dev launcher script

**Files:**
- Create: `bin/dev`

**Step 1: Write the launcher script**

Port `agent-container.sh` with these changes:
- Container naming: `<repo>-<branch>` instead of `mmir-agent-<branch>`
- Image name: `dev-env:latest` instead of `mmir-agent:latest`
- Build context: always `~/dot-files` (not repo-relative)
- Remove: MMIR-specific env vars (OPENCAGE, GEONAMES, LIBPOSTAL, devenv sourcing)
- Remove: GHCR login (no private base image)
- Remove: mmir cache volume mount
- GitHub token: prefer `gh auth token`, fall back to `GITHUB_TOKEN` env var
- Add `--add-host host.docker.internal:host-gateway` for service access

```bash
#!/usr/bin/env bash
# Universal dev container launcher for Claude Code.
# Runs Claude in an isolated Docker container from any project directory.
#
# Usage:
#   dev build [--no-cache]   Build the dev-env image
#   dev start                Start container with workspace mounted
#   dev shell                Interactive bash shell in container
#   dev claude [args...]     Run claude --dangerously-skip-permissions
#   dev reclaude [args...]   Stop and restart with claude
#   dev stop                 Stop and remove container
#   dev status               Show container status

set -euo pipefail

DOTFILES_DIR="${HOME}/dot-files"
IMAGE_NAME="dev-env:latest"
HOST_CLAUDE_DIR="${HOME}/.claude"

# Container name: <repo>-<branch> (unique across projects and worktrees)
REPO="$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "dev")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/' '-' || echo "main")"
CONTAINER_NAME="${REPO}-${BRANCH}"
BRANCH_CLAUDE_DIR="${HOME}/.claude-containers/${CONTAINER_NAME}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() { echo -e "${RED}ERROR: $1${NC}" >&2; exit 1; }
info()  { echo -e "${GREEN}>>> $1${NC}"; }
warn()  { echo -e "${YELLOW}>>> $1${NC}"; }

check_requirements() {
    command -v docker >/dev/null 2>&1 || error "docker not found. Install from https://docs.docker.com/get-docker/"
}

build_env_flags() {
    local -n _flags=$1

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

container_build() {
    check_requirements

    local no_cache=""
    if [[ "${1:-}" == "--no-cache" ]]; then
        no_cache="--no-cache"
    fi

    [[ -d "${DOTFILES_DIR}" ]] || error "dot-files not found at ${DOTFILES_DIR}"

    local github_token=""
    if command -v gh >/dev/null 2>&1; then
        github_token=$(gh auth token 2>/dev/null || true)
    fi
    if [[ -z "$github_token" ]]; then
        github_token="${GITHUB_TOKEN:-}"
    fi
    if [[ -z "$github_token" ]]; then
        warn "No GitHub token available - ubi may hit API rate limits"
    fi

    info "Building image '${IMAGE_NAME}'..."
    GITHUB_TOKEN="${github_token}" docker build \
        -f "${DOTFILES_DIR}/Dockerfile.dev" \
        -t "${IMAGE_NAME}" \
        --progress=plain \
        --secret id=github_token,env=GITHUB_TOKEN \
        --build-arg "AGENT_UID=$(id -u)" \
        --build-arg "AGENT_GID=$(id -g)" \
        --build-context "dotfiles=${DOTFILES_DIR}" \
        ${no_cache} \
        "${DOTFILES_DIR}"
    info "Build complete: ${IMAGE_NAME}"
}

container_start() {
    check_requirements

    docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1 \
        || error "Image '${IMAGE_NAME}' not found. Run: dev build"

    if docker ps --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        warn "Container '${CONTAINER_NAME}' is already running"
        return 0
    fi

    # Remove stopped container with same name
    if docker ps -a --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        info "Removing stopped container '${CONTAINER_NAME}'..."
        docker rm "${CONTAINER_NAME}" >/dev/null
    fi

    mkdir -p "${BRANCH_CLAUDE_DIR}"
    touch "${BRANCH_CLAUDE_DIR}/history.jsonl"

    info "Starting container '${CONTAINER_NAME}'..."

    local env_flags=()
    build_env_flags env_flags

    local volume_flags=(
        --volume "$(pwd):/workspace"
        --volume "${BRANCH_CLAUDE_DIR}:/home/agent/.claude/projects"
        --volume "${BRANCH_CLAUDE_DIR}/history.jsonl:/home/agent/.claude/history.jsonl"
    )
    [[ -f "${HOME}/.claude.json" ]] && \
        volume_flags+=(--volume "${HOME}/.claude.json:/home/agent/.claude.json")
    [[ -f "${HOST_CLAUDE_DIR}/.credentials.json" ]] && \
        volume_flags+=(--volume "${HOST_CLAUDE_DIR}/.credentials.json:/home/agent/.claude/.credentials.json")
    [[ -f "${HOST_CLAUDE_DIR}/settings.json" ]] && \
        volume_flags+=(--volume "${HOST_CLAUDE_DIR}/settings.json:/home/agent/.claude/settings.json")

    # Git worktree support: mount main .git dir at same absolute path
    local git_common_dir
    git_common_dir=$(git -C "$(pwd)" rev-parse --git-common-dir 2>/dev/null || true)
    if [[ -n "${git_common_dir}" && "${git_common_dir}" != ".git" ]]; then
        git_common_dir=$(cd "${git_common_dir}" && pwd)
        volume_flags+=(--volume "${git_common_dir}:${git_common_dir}")
    fi

    docker run -d \
        --name "${CONTAINER_NAME}" \
        --hostname dev-agent \
        --add-host host.docker.internal:host-gateway \
        "${volume_flags[@]}" \
        --workdir /workspace \
        "${env_flags[@]}" \
        "${IMAGE_NAME}" \
        sleep infinity

    info "Container started. Run: dev claude"
}

_ensure_running() {
    if ! docker ps --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        info "Container not running, starting it..."
        container_start
    fi
}

container_shell() {
    check_requirements
    _ensure_running
    info "Opening shell in '${CONTAINER_NAME}'..."
    docker exec -it "${CONTAINER_NAME}" bash -l
}

container_claude() {
    check_requirements
    _ensure_running

    local extra_args=""
    if [[ $# -gt 0 ]]; then
        extra_args=" $(printf '%q ' "$@")"
    fi

    info "Starting Claude Code in container..."
    docker exec -it "${CONTAINER_NAME}" bash -l -c "claude --dangerously-skip-permissions${extra_args}" || true
    info "Claude session ended. Container still running. Use 'dev stop' to remove."
}

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
    info "Container '${CONTAINER_NAME}' removed"
    info "Session history preserved at ${BRANCH_CLAUDE_DIR}"
}

container_status() {
    check_requirements

    echo ""
    echo "Container:  ${CONTAINER_NAME}"
    echo "Image:      ${IMAGE_NAME}"
    echo "Repo:       ${REPO}"
    echo "Branch:     ${BRANCH}"
    echo ""

    if docker ps --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        local created
        created=$(docker inspect "${CONTAINER_NAME}" --format '{{.Created}}' 2>/dev/null | cut -dT -f1)
        echo -e "Status:    ${GREEN}running${NC} (started ${created})"
        echo ""
        echo "Commands:"
        echo "  dev shell   - Interactive shell"
        echo "  dev claude  - Start Claude session"
        echo "  dev stop    - Stop and remove"
    elif docker ps -a --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "Status:    ${YELLOW}stopped${NC}"
        echo ""
        echo "Commands:"
        echo "  dev start   - Start container"
    else
        echo -e "Status:    ${RED}not created${NC}"
        echo ""
        echo "Commands:"
        echo "  dev build   - Build image"
        echo "  dev start   - Start container"
    fi

    echo ""
    if [[ -d "${BRANCH_CLAUDE_DIR}" ]]; then
        echo -e "Session dir: ${GREEN}exists${NC} (${BRANCH_CLAUDE_DIR})"
    else
        echo -e "Session dir: ${YELLOW}not created yet${NC}"
    fi
    echo ""
}

case "${1:-}" in
    build)   shift; container_build "$@" ;;
    start)   container_start ;;
    shell)   container_shell ;;
    claude)  shift; container_claude "$@" ;;
    reclaude) shift; container_stop; container_claude "$@" ;;
    stop)    container_stop ;;
    status)  container_status ;;
    *)
        echo "Usage: dev {build|start|shell|claude|reclaude|stop|status}"
        echo ""
        echo "Commands:"
        echo "  build [--no-cache]   Build the dev-env image"
        echo "  start                Start container with workspace mounted"
        echo "  shell                Interactive bash shell in container"
        echo "  claude [args...]     Run claude --dangerously-skip-permissions"
        echo "  reclaude [args...]   Stop and restart with claude"
        echo "  stop                 Stop and remove container"
        echo "  status               Show container status"
        echo ""
        echo "Container: ${CONTAINER_NAME} (per repo+branch)"
        echo "Sessions:  ~/.claude-containers/${CONTAINER_NAME}/"
        exit 1
        ;;
esac
```

**Step 2: Make executable**

Run: `chmod +x ~/dot-files/bin/dev`

**Step 3: Commit**

```bash
git add bin/dev
git commit -m "feat: add bin/dev launcher for universal dev containers"
```

---

### Task 3: Add bin/dev symlink to installer

**Files:**
- Modify: `installer/symlinks.sh`

**Step 1: Read installer/symlinks.sh to find the scripts section**

Look for the existing symlink block that links scripts (e.g., `add-worktree`, `remove-worktree`, `tm`).

**Step 2: Add dev symlink**

Add to the scripts symlink section in `installer/symlinks.sh`:

```bash
ln -sf ~/dot-files/bin/dev ~/local/bin/dev
```

This goes alongside the existing `ln -sf` lines for `add-worktree`, `remove-worktree`, and `tm`.

**Step 3: Commit**

```bash
git add installer/symlinks.sh
git commit -m "feat: add bin/dev to symlinks installer"
```

---

### Task 4: Test the image build

**Step 1: Run the build**

Run: `dev build`

This will take several minutes on first run (downloading Ubuntu, Node.js, Go, Playwright, Go tools, Claude plugins).

**Step 2: Verify the image exists**

Run: `docker image ls dev-env`
Expected: One row showing `dev-env latest <image-id> <date> <size>`

**Step 3: Test container start and shell**

```bash
cd ~/dot-files
dev start
dev shell
# Inside container:
which claude && which node && which go && which npx && exit
```

**Step 4: Test claude session isolation**

```bash
dev claude --help
dev stop
dev status
```

**Step 5: Commit any fixes needed**

If the build revealed issues (e.g., package names, paths), fix and commit each separately.

---

### Task 5: Add .claude-containers to global gitignore

**Files:**
- Check: `gitignore_global` — verify `.claude-containers/` isn't needed there (it's in `$HOME`, not in repos, so likely not needed)

**Step 1: Verify**

The `~/.claude-containers/` directory is in `$HOME`, not inside any git repo, so no gitignore entry is needed. Skip this task unless testing reveals otherwise.

---

### Task 6: Add .dockerignore for build context

**Files:**
- Create: `.dockerignore` (if needed to speed up builds)

**Step 1: Check if builds are slow due to large context**

If `docker build` sends a large context, create `.dockerignore`:

```
.git
node_modules
log.txt
```

Only create this if the build context is noticeably large. The dotfiles repo is small, so this may not be necessary.

**Step 2: Commit if created**

```bash
git add .dockerignore
git commit -m "chore: add .dockerignore to speed up dev container builds"
```
