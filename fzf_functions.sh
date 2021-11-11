# Keep fzf config and functions together
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--multi --pointer ">>"'

f () {
    fzf --bind='ctrl-/:toggle-preview' --preview "bat --style=numbers --color=always --line-range :500 {}" "$@"
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
    SESSION=$(tmux list-session | cut -d':' -f1 | fzf)
    if [ -z "$SESSION" ]; then
        echo "No session selected"
        return
    fi

    SUBCOMMAND="attach"

    if test "${TMUX_PANE+x}"; then
        SUBCOMMAND="switch"
    fi

    if [ $# -gt 0 ]; then
        SUBCOMMAND="$1"
    fi

    tmux "$SUBCOMMAND" -t "$SESSION"
}

# prove
_fzf_complete_prove() {
  _fzf_complete  --bind='ctrl-/:toggle-preview' --preview 'bat --style=numbers --color=always --line-range :50 {}' --reverse --multi --prompt="prove> " -- "$@" < <(
      fd -e t
  )
}

_fzf_complete_prove_post() {
    awk '{print $1}'
}

[ -n "$BASH" ] && complete -F _fzf_complete_prove -o default -o bashdefault prove
