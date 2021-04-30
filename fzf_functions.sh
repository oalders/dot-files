# Keep fzf config and functions together
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--multi --pointer ">>"'

f () {
    fzf --bind='ctrl-/:toggle-preview' --preview "bat --style=numbers --color=always --line-range :500 {}" "$@"
}

# Can't add this as a fzf completion for tmux as I need tmux itself to get a
# list of the running sessions.
tm() {
    SESSION=$(tmux list-session | cut -d' ' -f1 | fzf)
    if [ -z "$SESSION" ]; then
        echo "No session selected"
        return
    fi
    tmux attach "$@" -t "$SESSION"
}
