# Reset PATH to keep it from being clobbered in tmux
# https://github.com/dmend/dotfiles/blob/master/.bash_profile#L3-L7
if [ -x /usr/libexec/path_helper ]; then
    PATH=''
    source /etc/profile
fi

# Load .bashrc
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

if [ hash brew 2>/dev/null && -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

if [[ -d ~/.plenv ]]; then
    export PATH="$HOME/.plenv/bin:$PATH"
    eval "$(plenv init -)"
fi

if [[ -d ~/.rbenv ]]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
fi
export GPG_TTY=$(tty)

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/olaf/Documents/maxmind/google-cloud-sdk/path.bash.inc' ]; then . '/Users/olaf/Documents/maxmind/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/olaf/Documents/maxmind/google-cloud-sdk/completion.bash.inc' ]; then . '/Users/olaf/Documents/maxmind/google-cloud-sdk/completion.bash.inc'; fi
export GPG_TTY=$(tty)

# Make MacOS less annoying
export BASH_SILENCE_DEPRECATION_WARNING=1
