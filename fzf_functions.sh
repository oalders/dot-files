# Can't add this as a fzf completion for tmux as I need tmux itself to get a
# list of the running sessions.
tm() {
    SESSION=$(tmux list-session | cut -d' ' -f1 | fzf)
    tmux attach "$@" -t "$SESSION"
}
