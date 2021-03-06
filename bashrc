# shellcheck shell=sh

export EDITOR=vim

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

# shellcheck source=bash_functions.sh
. ~/dot-files/fzf_functions.sh

# use vim mappings to move around the command line
set -o vi

# don't put duplicate lines in the history. See bash(1) for more options
# http://www.linuxjournal.com/content/using-bash-history-more-efficiently-histcontrol
export HISTCONTROL=ignoreboth

# http://askubuntu.com/questions/80371/bash-history-handling-with-multiple-terminals
export PROMPT_COMMAND='history -a'

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=50000000
export HISTFILESIZE=500000000
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "

export CLICOLOR=1
export LSCOLORS=exfxcxdxbxegedabagacad

# https://superuser.com/a/975878/120685
alias brewski='brew update -v && brew upgrade && brew cleanup; brew doctor'
alias bytes_human='perl -MNumber::Bytes::Human -e "print Number::Bytes::Human::format_bytes shift"'
alias c="clear && tmux clear-history && perl -E 'say (qq{\n}x65,q{-}x78); system('date');print qq{-}x78, qq{\n}'"
alias cdr='cd `git root`'
alias d=docker
alias delete-merged-branches='show-merged-branches | xargs -n 1 git branch -d'
alias dangling-dockers='docker rmi -f $(docker images -f "dangling=true" -q)'
alias dzil-prove='dzil run --nobuild prove -lv'
alias dzil-prove-xs='dzil run prove -lv'
alias dzil-stale='dzil stale --all | xargs cpm install --global'
alias fix-gpg='pkill -9 gpg-agent && export GPG_TTY=$(tty)'
alias g=git
alias gdf='git domo|fpp'
alias grep='grep --color=auto --exclude-dir=.git'
alias heavy-cpu='ps --sort=-pcpu -aux|head -10'
alias hh='SwitchAudioSource -s "Built-in Output"'
alias l='ls -lAtr'
alias l.='ls -ldF .[a-zA-Z0-9]* --color=tty' #only show dotfiles
alias linebreaks="perl -pi -e 's/\r/\n/g'"
alias ll='ls -alhG'
alias lsd='ls --group-directories-first'
alias octal_perms='stat -c "%a %n"'
alias penv='perl -MDDP -e "p(%ENV)"'
alias pine=alpine
alias prune-local-branches='git remote prune origin && git branch -vv | grep -v origin'
alias redo='fpp --redo'
# http://stackoverflow.com/questions/13064613/how-to-prune-local-tracking-branches-that-do-not-exist-on-remote-anymore
alias show-local-only-branches="git branch -r | awk '{print \$1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print \$1}'"
alias show-merged-branches='git branch --no-color --merged | grep -v "\*" | grep -v master'
alias ssh-fingerprints='ls ~/.ssh/*.pub | xargs -L 1 ssh-keygen -l -f'
alias stp='git status | fpp --no-file-checks'
# https://stackoverflow.com/a/19280187/406224
alias takeover="tmux detach -a"
alias tidy-test-imports='find t -type f | grep "\.t$" | xargs -L 1 perlimports --libs lib,t/lib -i --log-level notice --ignore-modules Test::More -f'
alias tidy-lib-imports='find lib -type f | grep "\.pm$" | xargs -n 1 perlimports -i --log-level notice --libs lib -f'
alias tg='tidyall -g && git add -p'
alias wat='ps --sort=-pcpu -aux|head -10'
alias xpasswd='perl -MCrypt::XkcdPassword -E "say Crypt::XkcdPassword->make_password"'

# python scripts via pip install --user
add_path "$HOME/Library/Python/3.8/bin"
add_path "$HOME/.local/bin"

add_path "/usr/local/sbin"
add_path "$HOME/local/bin"

# node modules locally installing bin files
add_path "$HOME/dot-files/node_modules/.bin"

# Homebrew installs some binaries here
add_path "/usr/local/sbin"
add_path "/usr/local/bin"

# Rust binaries installed via cargo
add_path "$HOME/.cargo/bin"

# Haskell binaries installed via cabal
add_path "$HOME/.cabal/bin"

LOCALPERLBIN=~/perl5/bin

if [[ $IS_MM = false && ! -d ~/.plenv && -d $LOCALPERLBIN ]]; then
    export PERL_CPANM_OPT="--local-lib=~/perl5"
    # adds $HOME/perl5/bin to PATH
    [ "$SHLVL" -eq 1 ] && eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"

    if [ -d $LOCALPERLBIN ]; then
        add_path $LOCALPERLBIN
    fi
fi

# path used to be an alias, but that keeps a copy of $PATH in it, which is
# really confusing
alias | grep path && unalias path

# remove some aliases that override real binaries
alias | grep " df=" && unalias df
alias | grep " du=" && unalias du
alias | grep " ls=" && unalias ls
alias | grep " ps=" && unalias ps

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
    sudo lsof -s | awk '$5 == "REG"' | sort -n -r -k 7,7 | head -n 50
}

git-recover-file() {
    git checkout $(git rev-list -n 1 HEAD -- "$1")^ -- "$1"
}

md() {
    pandoc "$1" | lynx -stdin
}

if [ -f /etc/bash_completion.d/git ]; then
    source /etc/bash_completion.d/git
elif [ -f /usr/local/bin/brew ]; then
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
        . $(brew --prefix)/etc/bash_completion
    fi
fi

if ! type "ack" >/dev/null 2>&1; then
    if type 'ack-grep' >/dev/null 2>&1; then
        alias ack='ack-grep'
    fi
fi

youtube-mp3() { youtube-download "$1" && ffmpeg -i "$1.mp4" "$1.mp3"; }

tmux_session_name() {
    INSIDE_GIT_REPO="$(git rev-parse --is-inside-work-tree 2>/dev/null)"

    if [ "$INSIDE_GIT_REPO" ]; then
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        CURRENT_DIR=${PWD##*/}

        SESSION_NAME="$CURRENT_DIR    $BRANCH"
    else
        SESSION_NAME=$(pwd)
        STRIP="$HOME/"
        SESSION_NAME=${SESSION_NAME/$STRIP/}
    fi

    # A "." will produce a "bad session name" error
    SESSION_NAME=${SESSION_NAME//./-}
    export SESSION_NAME
}

# https://raim.codingfarm.de/blog/2013/01/30/tmux-update-environment/
function tmux() {
    local tmux=$(type -fp tmux)
    case "$1" in
    update-environment | update-env | ue)
        local v
        while read v; do
            if [[ $v == -* ]]; then
                unset ${v/#-/}
            else
                # Add quotes around the argument
                v=${v/=/=\"}
                v=${v/%/\"}
                eval export "$v"
            fi
        done < <(tmux show-environment)
        ;;
    # https://gist.github.com/marczych/10524654
    ns)
        tmux_session_name
        tmux rename-session "$SESSION_NAME"
        ;;
    '')
        tmux_session_name
        tmux new -s "$SESSION_NAME"
        ;;
    *)
        $tmux "$@"
        ;;
    esac
}

export FPP_DIR="$HOME/.fpp"
function fpp() {
    local fpp=$(type -fp fpp)

    HISTORY_FILE="$FPP_DIR/.fpp_history"
    FPP_CACHE="$FPP_DIR/.fpp.sh"

    touch "$HISTORY_FILE"

    # fpp --history just displays entire history prefixed by line numbers
    # fpp --redo will re-exec the last entry in the history file
    # fpp --redo -1 will also re-exec the last entry in the history file
    # fpp --redo -2 will re-exec the second last line in the history file
    # fpp --redo 11 will re-exec entry number 11 in the history file
    case "$1" in
    --history)
        cat -n "$HISTORY_FILE"
        return 1
        ;;
    --redo)
        if [ "$2" ]; then
            if [ "$2" -gt 0 ]; then
                LAST_HISTORY_LINE=$(head -n "$2" "$HISTORY_FILE" | tail -n 1)
            else
                LINE_NUMBER=$(($2 * -1))
                LAST_HISTORY_LINE=$(tail -n "$LINE_NUMBER" "$HISTORY_FILE" | head -n 1)
            fi
        else
            LAST_HISTORY_LINE=$(tail -n 1 "$HISTORY_FILE")
        fi

        eval "$LAST_HISTORY_LINE"
        return 1
        ;;
    esac

    LAST_HISTORY_LINE=$(tail -n 1 "$HISTORY_FILE")
    $fpp "$@"
    LAST_COMMAND=$(tail -n 2 "$FPP_CACHE" | head -n 1)

    # Don't keep adding the same command to the history file.
    # Also, don't log a message about a no-op.

    if [[ ("$LAST_COMMAND" != '') && ("$LAST_COMMAND" != "$LAST_HISTORY_LINE") ]]; then
        echo "$LAST_COMMAND" >>"$HISTORY_FILE"

        # This doesn't work yet.
        #HISTFILE=~/.bash_history
        #set -o history
        #history -s "$LAST_COMMAND"
    fi
}

# http://www.somethingorothersoft.com/2012/05/22/pulling-github-pull-requests-with-git/
# fetch-pull-request origin 1234
fetch-pull-request() {
    git fetch "$1" "refs/pull/$2/head:refs/remotes/pr/$2"
    git co -b "pr/$2" "pr/$2"
}
source ~/dot-files/inc/oh-my-git/prompt.sh

# make sure NERDTree arrows work
export LANG=en_US.UTF-8

source ~/dot-files/inc/finna-be-octo-hipster/iterm2_helpers.sh

if [ -d $GOPATH ]; then
    export PATH="$GOPATH/bin:$PATH"
fi

# https://unix.stackexchange.com/questions/19317/can-less-retain-colored-output
fancydiff() {
    git "$1" --color=always "$2" | diff-so-fancy | less -R
}

SOCK=~/.ssh/ssh_auth_sock
if test $SSH_AUTH_SOCK && test $TMUX && [ $SSH_AUTH_SOCK != $SOCK ]; then
    export SSH_AUTH_SOCK=$SOCK
fi

NPM_PACKAGES="${HOME}/.npm-packages"

add_path "$NPM_PACKAGES"

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
[ -f "$HOME"/.vim/plugged/fzf/shell/key-bindings.bash ] && source "$HOME"/.vim/plugged/fzf/shell/key-bindings.bash
[ -f "$HOME"/.vim/plugged/fzf/shell/completion.bash ] && source "$HOME"/.vim/plugged/fzf/shell/completion.bash

add_path "/usr/local/go/bin"

# Do this late so that any local additions to $PATH will come first
# shellcheck disable=SC1090
[ -f ~/local-dot-files/local_bashrc ] && . ~/local-dot-files/local_bashrc

# homebrew's curl needs to come first
add_path "/usr/local/opt/curl/bin"

if [[ ("${BASH_VERSINFO[0]}" -gt 3 ) && -f /usr/local/bin/cz ]]; then
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
[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env
