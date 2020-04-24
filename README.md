# My Dot Files

<!-- vim-markdown-toc GFM -->

* [tmux Prefix](#tmux-prefix)
* [tmux Plugins](#tmux-plugins)
* [tmux-resurrect](#tmux-resurrect)
* [vim](#vim)
* [Alfred](#alfred)
* [Yarn](#yarn)
* [Bash](#bash)

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
* `ctrl-o` - return to previous position in file
* `ý¿¿»šº:vertical terminal` - vertical split into a terminal buffer
* `:GFiles` - `git ls-files | fzf`
* `:GFiles?` - `git status | fzf` with preview pane
* `:BCommits` - git commits for the current buffer
* `:Maps` - fzf normal mode mappings
* `:BLines` - fzf lines in current buffer
* `:Lines` - fzf lines in loaded buffers
* `:GenTocGFM` - generate GitHub flavoured markdown table of contents

## Alfred

After Alfred and Dash are installed, click the `Integration` tab in `Dash` and
then choose `Alfred`.  If, for instance the `HTTP Status Codes` cheat sheet has
been downloaded via `Dash`, this will then be available in Alfred using `http`
to begin the search.

## Yarn

Upgrade deps via `yarn upgrade`.

## Bash

* `fc` - open previous command in `$EDITOR`
* `fc 2009` - open line 2009 of `history` in `$EDITOR`
