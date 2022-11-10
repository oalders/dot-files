# My Dot Files

<!-- vim-markdown-toc GFM -->

  * [tmux Prefix](#tmux-prefix)
  * [tmux Plugins](#tmux-plugins)
  * [tmux-resurrect](#tmux-resurrect)
  * [vim](#vim)
  * [Alfred](#alfred)
  * [Bash](#bash)
  * [macOS](#macos)
  * [less](#less)
  * [gh -- GitHub CLI](#gh----github-cli)
* [Testing with Docker](#testing-with-docker)

<!-- vim-markdown-toc -->

[![Actions Status](https://github.com/oalders/dot-files/workflows/Build/badge.svg)](https://github.com/oalders/dot-files/actions)

## tmux Prefix

Ctrl-a

## tmux Plugins

* prefix + r # reload config
* prefix + I # fetch and source plugins

## tmux-resurrect

* prefix + Ctrl-s - save
* prefix + Ctrl-r - restore

## vim

Remind myself of vim shortcuts etc.

* `:bp` - previous buffer
* `:bn` - next buffer
* `ctrl-w =` - equalize width and height of all windows
* `ctrl-w m` - toggle zooming of splits
* `ctrl-w r` - swap splits
* `ctrl-o` - return to previous position in file
* `ý¿¿»šº:vertical terminal` - vertical split into a terminal buffer
* `:GFiles` - `git ls-files | fzf`
* `:GFiles?` - `git status | fzf` with preview pane
* `:BCommits` - git commits for the current buffer
* `:Maps` - fzf normal mode mappings
* `:BLines` - fzf lines in current buffer
* `:Lines` - fzf lines in loaded buffers
* `:GenTocGFM` - generate GitHub flavoured markdown table of contents
* `[c` and `]c` - navigate to next changed hunk
* `gwip` - reflow a block of text and maintain cursor position

## Alfred

After Alfred and Dash are installed, click the `Integration` tab in `Dash` and
then choose `Alfred`.  If, for instance the `HTTP Status Codes` cheat sheet has
been downloaded via `Dash`, this will then be available in Alfred using `http`
to begin the search.

## Bash

* `fc` - open previous command in `$EDITOR`
* `fc 2009` - open line 2009 of `history` in `$EDITOR`

## macOS

* Set default shell to bash: `chsh -s /bin/bash`
* Eject disc from superdrive: `/usr/bin/drutil eject`

## less

When using `less` as a pager for `psql`, you can pass `less` directives while
viewing outpt.

* `-S` toggle horizontal scrolling
* `-N` toggle line numbers
* `10 + arrow key` will now advance horizontal scroll by 10 characters when arrow keys are pressed

## gh -- GitHub CLI

* `gh pr status`: status of all pull requests in repo
* `gh pr view 1234`: view a single pull request
  * `gh pr view --comments 1234`: view pull request and comments
* `gh pr checks`: get status of checks for a PR in current branch

# Testing with Docker

```
docker build -t dotfiles .
docker run -it --volume $PWD:/root/dot-files dotfiles:latest /bin/bash
```

In the Docker container:

```
cd /root/dot-files
USER=root ./install.sh
```
