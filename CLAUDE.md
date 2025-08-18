# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing configuration files, shell scripts, and automation tools for setting up development environments across macOS and Linux systems. The repository focuses on shell scripting, configuration management, and development tool setup.

## Key Commands

### Installation and Setup
- `./install.sh` - Main installation script that runs platform-specific and general installers
- `./installer/symlinks.sh` - Creates symbolic links for configuration files
- `./installer/homebrew.sh` - Installs Homebrew packages and casks (macOS)
- `./installer/npm.sh` - Installs Node.js packages
- `./installer/cpan.sh` - Installs Perl dependencies
- `./installer/cargo.sh` - Installs Rust packages

### Code Quality and Linting
- `precious tidy` - Auto-format shell scripts (shfmt) and Lua files (stylua)
- `precious lint` - Lint shell scripts and Lua files without modification
- `markdownlint-cli **/*.md` - Lint Markdown files
- `shfmt -w -s -i 4 **/*.sh` - Format shell scripts
- `stylua --check **/*.lua` - Check Lua formatting

### Testing
- Docker-based testing via `docker-compose up` or `docker-compose run --rm app /bin/env bash`
- Inside Docker container: `USER=root ./installer/inside-docker.sh && ./install.sh`

## Repository Architecture

### Core Structure
- **installer/** - Modular installation scripts for different tools and languages
  - Platform-specific installers (homebrew.sh, linux.sh)
  - Language-specific installers (npm.sh, cpan.sh, cargo.sh, etc.)
  - Tool-specific installers (nvim.sh, tmux.sh, git-fuzzy.sh, etc.)
- **configure/** - Configuration setup scripts for various tools
  - git.sh, ssh.sh, vim.sh, tmux.sh, bat.sh, etc.
- **bash_functions.sh** - Core shell utilities including path management and environment detection
- **install.sh** - Main orchestration script with debouncing logic

### Configuration Files
- **nvim/** - Neovim configuration with Lua-based setup
- **hammerspoon/** - macOS automation scripts with Spoons
- **tmux.conf** - tmux configuration
- **vimrc** - Vim configuration
- **bashrc**, **bash_profile** - Shell configuration
- **gitignore_global** - Global Git ignore patterns

### Tool Configuration
- **precious.toml** - Code formatting tool configuration
- **package.json** - Node.js dependencies for linting and formatting tools
- **typos.toml**, **selene.toml**, **golangci.yml** - Various linter configurations

## Development Patterns

### Debouncing System
The installation system uses a debouncing mechanism to avoid running expensive operations too frequently:
- `debounce 1 d ./installer/homebrew.sh` - Run at most once per day
- `debounce 30 days ./configure/eza.sh` - Run at most once per month

### Platform Detection
Uses `is os name eq darwin` pattern for macOS-specific operations and cross-platform compatibility.

### Modular Design
- Each installer is self-contained and can be run independently
- Installers are organized by category (language, tool, platform)
- Configuration scripts are separate from installation scripts

### Error Handling
Scripts use `set -eu -o pipefail` for strict error handling and early exit on failures.

## File Naming Conventions
- Shell scripts use `.sh` extension
- Configuration files often omit extensions (tmux.conf, vimrc, bashrc)
- Tool-specific configs use tool name as prefix (perlcriticrc, perltidyrc)
- Git-related scripts use `git-` prefix