# My Dot Files

<!-- vim-markdown-toc GFM -->

* [Fresh macOS Installs](#fresh-macos-installs)
  * [Clone Repo and Change Remote](#clone-repo-and-change-remote)
  * [Change Default shell](#change-default-shell)
  * [Trackpad and Dock defaults](#trackpad-and-dock-defaults)
  * [Install App Store Apps](#install-app-store-apps)
  * [Hammerspoon Spoon Installer](#hammerspoon-spoon-installer)
  * [Alfred Workflows](#alfred-workflows)
  * [Alfred Nord Theme](#alfred-nord-theme)
* [All Fresh Installs](#all-fresh-installs)
  * [Plenv](#plenv)
* [tmux](#tmux)
  * [Prefix](#prefix)
  * [Shortcuts](#shortcuts)
  * [Plugins](#plugins)
    * [tmux-resurrect](#tmux-resurrect)
* [vim](#vim)
  * [LSP](#lsp)
  * [State](#state)
  * [Mason](#mason)
* [Alfred](#alfred)
* [Bash](#bash)
* [less](#less)
* [gh -- GitHub CLI](#gh----github-cli)
* [Testing with Docker](#testing-with-docker)
* [Docker bashrc](#docker-bashrc)
* [Hammerspoon](#hammerspoon)
  * [Seal](#seal)
    * [cpan-repo](#cpan-repo)
    * [Slackify Name](#slackify-name)
    * [xpasswd](#xpasswd)

<!-- vim-markdown-toc -->

[![Actions Status](https://github.com/oalders/dot-files/workflows/Build/badge.svg)](https://github.com/oalders/dot-files/actions)

## Fresh macOS Installs

Some of these scripts will need to be run manually on a fresh install. They may
require manual intervention or be impractical to run regularly.

### Clone Repo and Change Remote

```text
git clone https://github.com/oalders/dot-files.git
cd dot-files
./bin/change-dot-files-origin.sh
```

### Change Default shell

See <https://apple.stackexchange.com/a/232983>

On macOS:

`sudo vi /etc/shells`

Afterwards it should look something like:

```text
# List of acceptable shells for chpass(1).
# Ftpd will not allow users to connect who are not using
# one of these shells.

/bin/bash
/bin/csh
/bin/dash
/bin/ksh
/bin/sh
/bin/tcsh
/bin/zsh
/opt/homebrew/bin/bash
```

Then:

```bash
chsh -s /opt/homebrew/bin/bash $USER
```

### Trackpad and Dock defaults

```bash
./configure/macos.sh
```

### Install App Store Apps

On my personal machines after I'm logged in to the app store:

```bash
brew bundle install --file=brew/mas
```

### Hammerspoon Spoon Installer

```bash
./installer/spoon-installer.sh
```

Then double-click the `SpoonInstall.spoon` file. This fixes the following error:

> Unable to load Spoon: SpoonInstall

### Alfred Workflows

```bash
installer/alfred-workflows.sh
```

Run after Alfred has been installed. Confirm each install individually.

### Alfred Nord Theme

[Install Alfred Nord Theme](https://www.alfredapp.com/extras/theme/5Y8E7URIWQ/)

## All Fresh Installs

### Plenv

```bash
./installer/plenv.sh
```

Install `plenv` as well as the latest Perl version.

## tmux

### Prefix

`ctrl-a`

### Shortcuts

`ctrl-a + L`: toggle session

### Plugins

* prefix + r # reload config
* prefix + I # install plugins

#### tmux-resurrect

* prefix + Ctrl-s - save
* prefix + Ctrl-r - restore
* `rm -rf ~/.cache/tmux/resurrect` - clear saved sessions

## vim

Remind myself of vim shortcuts etc.

* `:BCommits` - git commits for the current buffer
* `:BLines` - fzf lines in current buffer
* `:bn` or `]b` - next buffer
* `:bp` or `[b` - previous buffer
* `[c` and `]c` - navigate to next changed hunk
  close the terminal
* `crn` - LSP rename
* `crr` - LSP code action
* `ctrl-l` - clear highlighted search terms
* `ctrl-o` - return to previous position in file
* `ctrl-w =` - equalize width and height of all windows
* `ctrl-w m` - toggle zooming of splits
* `ctrl-w r` - swap splits
* `DiffviewOpen HEAD~1` - view diff. Probably follow with `:colo iceberg`
* `]d` - next diagnostic
* `[d` - previous diagnostic
* `gc` - toggle commenting on a visual selection
* `gcc` - toggle commenting on line under cursor
* `gd` - go to definition
* `:GenTocGFM` - generate GitHub flavoured markdown table of contents
* `:GFiles` - `git ls-files | fzf`
* `:GFiles?` - `git status | fzf` with preview pane
* `gO` - open a loc list with the table of contents for a help file
* `gr` - get references
* `gwip` - reflow a block of text and maintain cursor position
* `gx` - in normal mode calls `vim.ui.open()` on whatever is under the cursor
* `<leader>gm` - show commit message for line under cursor
* `:Lines` - fzf lines in loaded buffers
* `:Maps` - fzf normal mode mappings
* `:Splitrun precious tidy --git` - run a command in a split
* `:vert(ical) terminal` - vertical split into a terminal buffer. `exit` to

See `akinsho/bufferline.nvim` for buffer config.

### LSP

`:LspLog` displays path to log file at the top

Print results of `vim.lsp.log.get_filename()`:

`:lua print(require('vim.lsp.log').get_filename())`

### State

Print location of state directory:

`:lua print(vim.fn.stdpath 'state')`

`:h stdpath()` for args that can be passed.

### Mason

Lockfiles. For instance, if it can't update or install `selene`, remove:
`./local/share/nvim/mason/staging/selene.lock`

## Alfred

After Alfred and Dash are installed, click the `Integration` tab in `Dash` and
then choose `Alfred`.  If, for instance the `HTTP Status Codes` cheat sheet has
been downloaded via `Dash`, this will then be available in Alfred using `http`
to begin the search.

## Bash

* `ctrl-e` - open current line in `$EDITOR`
* `fc` - open previous command in `$EDITOR`
* `fc 2009` - open line 2009 of `history` in `$EDITOR`

## less

When using `less` as a pager for `psql`, you can pass `less` directives while
viewing outpt.

* `-S` toggle horizontal scrolling
* `-N` toggle line numbers
* `10 + arrow key` will now advance horizontal scroll by 10 characters when
  arrow keys are pressed

## gh -- GitHub CLI

* `gh pr status`: status of all pull requests in repo
* `gh pr view 1234`: view a single pull request
  * `gh pr view --comments 1234`: view pull request and comments
* `gh pr checks`: get status of checks for a PR in current branch

## Testing with Docker

```bash
docker run -it --volume $PWD:/root/dot-files ubuntu:latest /bin/env bash
```

In the Docker container:

```bash
cd /root/dot-files
USER=root ./installer/inside-docker.sh && ./install.sh
```

## Docker bashrc

```text
docker run --rm -it -p 5000:5000                  \
-v "$HOME/dot-files/bashrc-docker:/root/.bashrc"  \
--volume $PWD:/sandbox                            \
python:latest bashrc
```

## Hammerspoon

### Seal

Launch Seal via `hyper` + `space`

#### cpan-repo

`hyper` + `space` + `cr OrePAN2`

#### Slackify Name

Select name. Then: `hyper` + `space` + `sl`

#### xpasswd

Enter insert mode. Then `hyper` + `space` + `xp`
