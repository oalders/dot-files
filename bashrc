# http://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   platform='linux'
elif [[ "$unamestr" == 'Darwin' ]]; then
   platform='osx'
fi

export EDITOR=vim

# use vim mappings to move around the command line
set -o vi

# don't put duplicate lines in the history. See bash(1) for more options
# http://www.linuxjournal.com/content/using-bash-history-more-efficiently-histcontrol
export HISTCONTROL=ignoreboth

# http://askubuntu.com/questions/80371/bash-history-handling-with-multiple-terminals
export PROMPT_COMMAND='history -a'

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=1000
export HISTFILESIZE=2000

export CLICOLOR=1
export LSCOLORS=exfxcxdxbxegedabagacad

alias batterylife='pmset -g batt | grep Internal | awk "{print $2}" | sed "s/;//"'
# https://superuser.com/a/975878/120685
alias brewski='brew update && brew upgrade && brew cleanup; brew doctor'
alias bytes_human='perl -MNumber::Bytes::Human -e "print Number::Bytes::Human::format_bytes shift"'
alias c='clear && tmux clear-history && perl -E "say (qq{\n}x65,q{-}x78); system('date');print qq{-}x78, qq{\n}"'
alias cdr='cd `git root`'
alias cpanx='cpanm --local-lib ~/perl5 --metacpan --mirror http://cpan.metacpan.org'
alias delete-merged-branches='show-merged-branches | xargs -n 1 git branch -d'
alias df='df -h'
alias du='du -h'
alias dzil-prove='dzil run --nobuild prove -lv t/my-test.t'
alias dzil-prove-xs='dzil run prove -lv t/my-test.t'
alias dzil-stale='dzil stale --all | xargs cpm install --global'
# https://serverfault.com/questions/207100/how-can-i-find-phantom-storage-usage
alias files-open-by-process="sudo lsof | awk '$5 == "REG" {freq[$2]++ ; names[$2] = $1 ;} END {for (pid in freq) print freq[pid], names[pid], pid ; }' | sort -n -r -k 1,1"
alias files-open-by-size="sudo lsof -s | awk '$5 == "REG"' | sort -n -r -k 7,7 | head -n 50"
alias gdf='git domo|fpp'
alias grep='grep --color=auto'
alias hh='SwitchAudioSource -s "Built-in Output"'
alias l='ls -lAtr'
alias l.='ls -ldF .[a-zA-Z0-9]* --color=tty' #only show dotfiles
alias linebreaks="perl -pi -e 's/\r/\n/g'"
alias ll='ls -alhG'
alias ls='ls -G'
alias lsd='ls --group-directories-first'
alias octal_perms='stat -c "%a %n"'
alias penv='perl -MDDP -e "p(%ENV)"'
alias pine=alpine
alias pretty='python -mjson.tool'
alias prune-local-branches='git remote prune origin && git branch -vv | grep -v origin'
alias ps='ps auxw'
alias redo='fpp --redo'
# http://stackoverflow.com/questions/13064613/how-to-prune-local-tracking-branches-that-do-not-exist-on-remote-anymore
alias show-local-only-branches="git branch -r | awk '{print \$1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print \$1}'"
alias show-merged-branches='git branch --no-color --merged | grep -v "\*" | grep -v master'
alias source-perlbrew='source ~/perl5/perlbrew/etc/bashrc'
alias ssh-fingerprints='ls ~/.ssh/*.pub | xargs -L 1 ssh-keygen -l -f'
alias stp='git status | fpp --no-file-checks'
# https://stackoverflow.com/a/19280187/406224
alias takeover="tmux detach -a"
alias tg='tidyall -g && git add -p'
alias xkcdalt='perl -MWWW::xkcd -E "say WWW::xkcd->new->fetch_metadata->{alt}"'
alias xpasswd='perl -MCrypt::XkcdPassword -E "say Crypt::XkcdPassword->make_password"'

# conversions
alias d2b="perl -e 'printf qq|%b\n|, int( shift )'"
alias d2h="perl -e 'printf qq|%X\n|, int( shift )'"
alias d2o="perl -e 'printf qq|%o\n|, int( shift )'"
alias h2b="perl -e 'printf qq|%b\n|, hex( shift )'"
alias h2d="perl -e 'printf qq|%d\n|, hex( shift )'"
alias h2o="perl -e 'printf qq|%o\n|, hex( shift )'"
alias o2b="perl -e 'printf qq|%b\n|, oct( shift )'"
alias o2d="perl -e 'printf qq|%d\n|, oct( shift )'"
alias o2h="perl -e 'printf qq|%X\n|, oct( shift )'"

# http://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:$PATH"
    fi
}

# python scripts via pip install --user
pathadd "$HOME/Library/Python/2.7/bin";
pathadd "$HOME/.local/bin";

pathadd "/usr/local/sbin";
pathadd "$HOME/local/bin";

LOCALPERLBIN=~/perl5/bin

if [[ ! -d ~/.plenv && -d $LOCALPERLBIN ]]; then
    PERL_CPANM_OPT="--local-lib=~/perl5"
    # adds $HOME/perl5/bin to PATH
    [ $SHLVL -eq 1 ] && eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"

    if [ -d $LOCALPERBIN ] ; then
        export PATH="$LOCALPERLBIN:$PATH"
    fi
fi

function whosonport {
    sudo lsof -i :$1;
}

function check_compression {
      curl -I -H 'Accept-Encoding: gzip,deflate' $1 | grep "Content-Encoding"
}

function trace_process {
    sudo lsof -p $1 && sudo strace -fp $1
}

function git-recover-file {
    git checkout $(git rev-list -n 1 HEAD -- "$1")^ -- "$1"
}

function md () {
    pandoc $1 | lynx -stdin
}

if [ -f /etc/bash_completion.d/git ]; then
    source /etc/bash_completion.d/git
elif [ -f /usr/local/bin/brew ]; then
    if [ -f `brew --prefix`/etc/bash_completion ]; then
        . `brew --prefix`/etc/bash_completion
    fi
fi

if ! type "ack" > /dev/null  2>&1; then
    if type 'ack-grep' > /dev/null 2>&1; then
        alias ack='ack-grep'
    fi
fi
function gi() { curl http://gitignore.io/api/$@ ;}

# gh = git home
# brings you to the top level of the git repo you are currently in
# http://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command
function gh() { cd "$(git rev-parse --show-toplevel)"; }

function youtube-mp3 { youtube-download $1 && ffmpeg -i $1.mp4 $1.mp3; }

function wwwman {
  perl -we 'use URI::Escape;$cmd=shift;$args = uri_escape(join q[  ],@ARGV);
           exec open => qq!http://explainshell.com/explain/$cmd?args=$args!' $@
}

# https://raim.codingfarm.de/blog/2013/01/30/tmux-update-environment/
function tmux() {
    local tmux=$(type -fp tmux)
    case "$1" in
        update-environment|update-env|ue)
            local v
            while read v; do
                if [[ $v == -* ]]; then
                    unset ${v/#-/}
                else
                    # Add quotes around the argument
                    v=${v/=/=\"}
                    v=${v/%/\"}
                    eval export $v
                fi
            done < <(tmux show-environment)
            ;;
        # https://gist.github.com/marczych/10524654
        ns)
            INSIDE_GIT_REPO="$(git rev-parse --is-inside-work-tree 2>/dev/null)"

            if [ $INSIDE_GIT_REPO ]; then
                BRANCH=$(git rev-parse --abbrev-ref HEAD)
                CURRENT_DIR=${PWD##*/}

                SESSION_NAME="$CURRENT_DIR ⚡ $BRANCH"
            else
               SESSION_NAME=$(pwd)
               STRIP="$HOME/"
               SESSION_NAME=${SESSION_NAME/$STRIP}
            fi

            # A "." will produce a "bad session name" error
            SESSION_NAME=${SESSION_NAME//./-}
            tmux rename-session "$SESSION_NAME"
            ;;
        *)
            $tmux "$@"
            ;;
    esac
}

# If the first arg to "vi" contains "::" then assume it's a Perl module that's
# either in lib or t/lib

function vi() {
    local vi=$(type -fp vim)
    string=$1
    if [[ ! $string == *"::"* ]]; then
        $vi "$@"
        return 1
    fi

    string=$(sed 's/::/\//g;' <<< $1)
    string="lib/$string.pm"
    if [[ ! -e $string ]]; then
        string="t/$string"
    fi
    $vi "$string"
}

function fpp() {
    local fpp=$(type -fp fpp)

    HISTORY_FILE="$HOME/.fpp/.fpp_history"
    FPP_CACHE="$HOME/.fpp/.fpp.sh"

    touch $HISTORY_FILE

    # fpp --history just displays entire history prefixed by line numbers
    # fpp --redo will re-exec the last entry in the history file
    # fpp --redo -1 will also re-exec the last entry in the history file
    # fpp --redo -2 will re-exec the second last line in the history file
    # fpp --redo 11 will re-exec entry number 11 in the history file
    case "$1" in
        --history)
        cat -n $HISTORY_FILE
        return 1
        ;;
        --redo)
        if [ $2 ] ; then
            if [ $2 \> 0 ] ; then
                LAST_HISTORY_LINE=$(head -n $2 $HISTORY_FILE |tail -n 1)
            else
                LINE_NUMBER=$(( $2 * -1))
                LAST_HISTORY_LINE=$(tail -n $LINE_NUMBER $HISTORY_FILE | head -n 1)
            fi
        else
            LAST_HISTORY_LINE=$(tail -n 1 $HISTORY_FILE )
        fi

        eval $LAST_HISTORY_LINE
        return 1
        ;;
    esac

    LAST_HISTORY_LINE=$(tail -n 1 $HISTORY_FILE)
    $fpp "$@"
    LAST_COMMAND=$(tail -n 2 $FPP_CACHE | head -n 1)

    # Don't keep adding the same command to the history file.
    # Also, don't log a message about a no-op.

    if [[ ("$LAST_COMMAND" != '') && ("$LAST_COMMAND" != "$LAST_HISTORY_LINE") ]] ; then
        echo $LAST_COMMAND >> $HISTORY_FILE
    fi
}

# http://www.somethingorothersoft.com/2012/05/22/pulling-github-pull-requests-with-git/
# fetch-pull-request origin 1234
fetch-pull-request () {
    git fetch $1 refs/pull/$2/head:refs/remotes/pr/$2;
    git co -b pr/$2 pr/$2;
}
source ~/dot-files/inc/oh-my-git/prompt.sh

# make sure NERDTree arrows work
export LANG=en_US.UTF-8

source ~/dot-files/inc/finna-be-octo-hipster/iterm2_helpers.sh

export GOPATH=~/go
if [ -d $GOPATH ] ; then
    export PATH="$GOPATH/bin:$PATH"
fi


if [[ $platform == 'osx' ]]; then
    export PATH="~/dot-files/bin/osx:$PATH"
fi

# clean up PATH
# http://linuxg.net/oneliners-for-removing-the-duplicates-in-your-path/
PATH=`echo -n $PATH | awk -v RS=: -v ORS=: '!arr[$0]++'`

# https://unix.stackexchange.com/questions/19317/can-less-retain-colored-output
fancydiff () {
    git $1 --color=always $2 | diff-so-fancy | less -R
}

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

SOCK=~/.ssh/ssh_auth_sock
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
if test $SSH_AUTH_SOCK && test $TMUX && [ $SSH_AUTH_SOCK != $SOCK ]; then
    export SSH_AUTH_SOCK=$SOCK
fi
