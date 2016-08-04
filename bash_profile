[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

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

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

if [ hash brew 2>/dev/null && -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
if [[ -d ~/.plenv ]]; then
    export PATH="$HOME/.plenv/bin:$PATH"
    eval "$(plenv init -)"
fi
