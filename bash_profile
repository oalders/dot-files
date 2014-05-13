export PATH=/usr/local/sbin:$PATH

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

if [ -d "$HOME/local/bin" ] ; then
    PATH="$HOME/local/bin:$PATH"
fi

if [ -d "$HOME/perl5/bin" ] ; then
    PATH="$HOME/perl5/bin:$PATH"
fi

if [ hash brew 2>/dev/null && -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi
