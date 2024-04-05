# shellcheck shell=bash
export CLICOLOR=1

# don't put duplicate lines in the history. See bash(1) for more options
# http://www.linuxjournal.com/content/using-bash-history-more-efficiently-histcontrol
export HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTFILESIZE=500000000
export HISTSIZE=50000000
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "

export LANG=en_US.UTF-8
export LSCOLORS=exfxcxdxbxegedabagacad

# http://askubuntu.com/questions/80371/bash-history-handling-with-multiple-terminals
export PROMPT_COMMAND='history -a'

# shellcheck source=bash_functions.sh
. ~/dot-files/bash_functions.sh

# shellcheck source=bash_functions.sh
. ~/dot-files/fzf_functions.sh

# use vim mappings to move around the command line
set -o vi

# https://superuser.com/a/975878/120685
alias bytes_human='perl -MNumber::Bytes::Human -e "print Number::Bytes::Human::format_bytes shift"'
alias c="clear && { [ -n \"$TMUX\" ] && tmux clear-history; }"
alias cdr='cd $(git root)'
alias date='date +"%a %d %b %Y %T %Z"'
alias delete-merged-branches='show-merged-branches | safe-xargs -n 1 git branch -d'
alias dangling-dockers='docker rmi -f $(docker images -f "dangling=true" -q)'
alias dr='NO_JIGSAW=1 HARNESS_OPTIONS="j8:c" dzil release'
alias dzil-prove='dzil run --nobuild prove -lv'
alias dzil-prove-xs='dzil run prove -lv'
alias dzil-stale='dzil stale --all | safe-xargs cpm install --global'
alias fix-gpg='pkill -9 gpg-agent && export GPG_TTY=$(tty)'
alias g=git
alias gi=git # fix typos
alias gri="git rebase -i origin/main"
alias git-clean="git gc && git-lfs prune"
alias gti=git # fix typos
alias go-clean="go clean -modcache"
alias grep='grep --color=auto --exclude-dir=.git'
alias l='ls -lAtr'
alias l.='ls -ldF .[a-zA-Z0-9]* --color=tty' #only show dotfiles
alias linebreaks="perl -pi -e 's/\r/\n/g'"
alias lsd='ls --group-directories-first'
alias octal_perms='stat -c "%a %n"'
alias pine=alpine
alias s='source ~/.bash_profile && source ~/dot-files/fzf_functions.sh'
# http://stackoverflow.com/questions/13064613/how-to-prune-local-tracking-branches-that-do-not-exist-on-remote-anymore
alias show-merged-branches='git branch --no-color --merged | grep -v "\*" | grep -v master | grep -v main | grep -v -e "^+" | grep -v -e "^*"'
alias ssh-fingerprints='ls ~/.ssh/*.pub | safe-xargs -L 1 ssh-keygen -l -f'
# https://stackoverflow.com/a/19280187/406224
alias takeover="tmux detach -a"
alias wat='ps --sort=-pcpu -aux|head -10'
alias xpasswd='perl -MCrypt::XkcdPassword -E "say Crypt::XkcdPassword->make_password"'

if is os name eq 'linux'; then
    alias safe-xargs='xargs --no-run-if-empty'
else
    alias safe-xargs='xargs'
fi

if is os name eq darwin; then
    alias updatedb="sudo /usr/libexec/locate.updatedb"

    # python scripts via pip install --user
    remove_path "$HOME/Library/Python/3.9/bin"
    add_path "$HOME/Library/Python/3.11/bin"
    export HOMEBREW_AUTO_UPDATE_SECS=86400

    add_path ~/local/bin/nvim-macos/bin
    # homebrew's curl needs to come first
    add_path "/usr/local/opt/curl/bin"

    # Homebrew installs some binaries here
    add_path "/usr/local/sbin"
    add_path "/usr/local/bin"

    # More modern homebrew uses
    add_path "/opt/homebrew/bin"
    add_path "/opt/homebrew/sbin"

fi

if is there nvim; then
    alias vi=nvim
    alias vim=nvim
    export EDITOR=nvim
else
    export EDITOR=vim
fi

add_path "$HOME/.local/bin"
add_path "$HOME/local/bin"
add_path "$HOME/local/bin/go/bin"

# node modules locally installing bin files
add_path "$HOME/dot-files/node_modules/.bin"

# Rust binaries installed via cargo
add_path "$HOME/.cargo/bin"

# Haskell binaries installed via cabal
add_path "$HOME/.cabal/bin"

add_path "$HOME/dot-files/src/git-fuzzy/bin"

localperlbin=~/perl5/bin

if [[ $IS_MM = false && ! -d ~/.plenv && -d $localperlbin ]]; then
    export PERL_CPANM_OPT="--local-lib=~/perl5"
    # adds $HOME/perl5/bin to PATH
    [ "$SHLVL" -eq 1 ] && eval "$(perl -I "$HOME/perl5/lib/perl5" -Mlocal::lib)"

    add_path $localperlbin
fi

whosonport() {
    sudo lsof +c 0 -i :"$1"
}

check_compression() {
    curl -I -H 'Accept-Encoding: gzip,deflate' "$1" | grep "Content-Encoding"
}

trace_process() {
    sudo lsof +c 0 -p "$1" && sudo strace -fp "$1"
}

open_files() {
    i=${1:-50}
    sudo lsof -s | awk '$5 == "REG"' | sort -n -r -k 7,7 | head -n "$i"
}

git_recover_file() {
    git checkout "$(git rev-list -n 1 HEAD -- "$1")"^ -- "$1"
}

md() {
    pandoc "$1" | lynx -stdin
}

if [ -f /etc/bash_completion.d/git ]; then
    . /etc/bash_completion.d/git
elif is there brew; then
    BREW_PREFIX=$(brew --prefix)
    if [ -f "$BREW_PREFIX/etc/bash_completion" ]; then
        . "$BREW_PREFIX/etc/bash_completion"
    fi
fi

unset -f tm
# https://raim.codingfarm.de/blog/2013/01/30/tmux-update-environment/
tmux() {
    local tmux
    tmux=$(type -fp tmux)

    if [ $# -ge 1 ] && [ -n "$1" ]; then
        case "$1" in
        update-environment | update-env | ue)
            local v
            while read -r v; do
                if [[ $v == -* ]]; then
                    echo "unset $v"
                    unset "${v/#-/}"
                else
                    # Add quotes around the argument
                    v=${v/=/=\"}
                    v=${v/%/\"}
                    echo "export $v"
                    eval export "$v"
                fi
            done < <(tmux show-environment)
            ;;
        # https://gist.github.com/marczych/10524654
        ns)
            tmux_session_name
            tmux rename-session "$SESSION_NAME"
            ;;
        *)
            $tmux "$@"
            ;;
        esac
    else
        tmux_session_name
        $tmux new -s "$SESSION_NAME"
    fi
}

add_path "$GOPATH/bin"

# shellcheck disable=SC2153
if test "$SSH_AUTH_SOCK" && test "$TMUX" && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock" ]; then
    export SSH_AUTH_SOCK=$SOCK
fi

# Unset manpath so we can inherit from /etc/manpath via the `manpath` command
unset MANPATH # delete if you already modified MANPATH elsewhere in your config
MANPATH="$NPM_PACKAGES/share/man:$(manpath)"
export MANPATH

# enable bash completion in interactive shells
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# If this happens *before* bash completion setup then command line tab
# completion via **<TAB> does not work.
add_path "$HOME/.vim/plugged/fzf/bin"
[ -f "$HOME"/.vim/plugged/fzf/shell/key-bindings.bash ] && . "$HOME"/.vim/plugged/fzf/shell/key-bindings.bash
[ -f "$HOME"/.vim/plugged/fzf/shell/completion.bash ] && . "$HOME"/.vim/plugged/fzf/shell/completion.bash

add_path "/usr/local/go/bin"

# Do this late so that any local additions to $PATH will come first
# shellcheck disable=SC1090
[ -f ~/local-dot-files/local_bashrc ] && . ~/local-dot-files/local_bashrc

if [[ ("${BASH_VERSINFO[0]}" -gt 3) && -f /usr/local/bin/cz ]]; then
    add_path "/usr/local/bin/cz"
    . /usr/local/bin/cz
    export CZ_GUI=0
    bind -x '"\C-xx":rleval "cz meta -q"'
    bind -x '"\C-xX":rleval "cz meta -p"'
    bind -x '"\C-xz":rleval "cz meta -r"'
    bind -x '"\C-xZ":rleval "cz meta -s"'
    bind -x '"\C-xc": "cz meta -r"'
fi

reset_path

[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

add_path ~/dot-files/bin
posh_me
