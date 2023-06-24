#!/bin/env bash

# Keep fzf config and functions together
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--multi --pointer ">>"'

f() {
    fzf --bind='ctrl-/:toggle-preview' --preview "bat --style=numbers --color=always --line-range :500 {}" "$@"
}

rm_worktree() {
    MY_XARGS_OPTIONS="--no-run-if-empty"
    if is os name eq darwin; then
        MY_XARGS_OPTIONS=""
    fi

    # Get list of worktrees and strip it down to the branch name
    # [oalders/branch-name], which should generally also correspond to the tmux
    # session name.
    git worktree list | fzf | sed -rn 's/.*\[(.*)\]/\1/gp' | xargs "$MY_XARGS_OPTIONS" remove-worktree "$@"
}

# Can't add this as a fzf completion for tmux as I need tmux itself to get a
# list of the running sessions.
#
# From the command line, to get a tmux session picker:
# tm<cr>
#
# to get a tmux kill-session picker:
# tm kill-session<cr>

tm() {
    SESSION=$(tmux list-session | cut -d':' -f1 | fzf --exit-0)
    if [ -z "$SESSION" ]; then
        echo "No session selected"
        return
    fi

    SUBCOMMAND="attach"

    # If there's an argument, then it should be a tmux subcommand
    if [ $# -gt 0 ]; then
        SUBCOMMAND="$1"

    # If we got this far then we're inside tmux and we'd need to switch rather
    # than attach, since we're avoiding nested sessions.
    elif test "${TMUX_PANE+x}"; then
        SUBCOMMAND="switch"
    fi

    tmux "$SUBCOMMAND" -t "$SESSION"
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
