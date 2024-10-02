#!/bin/env bash

# Keep fzf config and functions together
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# I want tab to move up and down in the list, just like it does with my vim
# completion. With this config tab moves down, shift-tab moves up and
# ctrl-space toggles selection.
export FZF_DEFAULT_OPTS="--multi --pointer '>>' --bind 'ctrl-space:toggle,tab:down,shift-tab:up'"

f() {
    fzf --bind='ctrl-/:toggle-preview' --preview "bat --style=numbers --color=always --line-range :500 {}" "$@"
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
    cd "$(git worktree list |
        fzf --preview='git log --pretty=format:"%ad %<(8,trunc)%aL %h %s" --date=format:"%Y-%m-%d" -n10 {2} | tac | tspin' \
            --preview-window 'up,border-horizontal' |
        awk '{print $1}')" || exit
}

rm_worktree() {
    # Get list of worktrees and strip it down to the branch name
    # [oalders/branch-name], which should generally also correspond to the tmux
    # session name.
    git worktree list |
        fzf --preview='cd {1} && git status' \
            --preview-window 'up,border-horizontal' |
        sed -rn 's/.*\[(.*)\]/\1/gp' |
        safe_xargs remove-worktree "$@"
}
