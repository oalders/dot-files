#!/bin/env bash

# Keep fzf config and functions together
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--multi --pointer ">>"'

f() {
    fzf --bind='ctrl-/:toggle-preview' --preview "bat --style=numbers --color=always --line-range :500 {}" "$@"
}

rm_worktree() {
    # Get list of worktrees and strip it down to the branch name
    # [oalders/branch-name], which should generally also correspond to the tmux
    # session name.
    git worktree list | fzf | sed -rn 's/.*\[(.*)\]/\1/gp' | safe-xargs remove-worktree "$@"
}

# prove
_fzf_complete_prove() {
    _fzf_complete --bind='ctrl-/:toggle-preview' --preview 'bat --style=numbers --color=always --line-range :50 {}' --reverse --multi --prompt="prove> " -- "$@" < <(
        fd -e t
    )
}

_fzf_complete_prove_post() {
    awk '{print $1}'
}

[ -n "$BASH" ] && complete -F _fzf_complete_prove -o default -o bashdefault prove

# yath
_fzf_complete_yath() {
    _fzf_complete --bind='ctrl-/:toggle-preview' --preview 'bat --style=numbers --color=always --line-range :50 {}' --reverse --multi --prompt="yath> " -- "$@" < <(
        fd -e t
    )
}

_fzf_complete_yath_post() {
    awk '{print $1}'
}

[ -n "$BASH" ] && complete -F _fzf_complete_yath -o default -o bashdefault yath

cd_worktree() {
    cd "$(git worktree list | fzf | awk '{print $1}')" || exit
}
