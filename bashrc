export EDITOR=vim

# use vim mappings to move around the command line
set -o vi

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignoredups

# http://askubuntu.com/questions/80371/bash-history-handling-with-multiple-terminals
export PROMPT_COMMAND='history -a'

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

alias batterylife='pmset -g batt | grep Internal | awk "{print $2}" | sed "s/;//"'
alias bytes_human='perl -MNumber::Bytes::Human -e "print Number::Bytes::Human::format_bytes shift"'
alias cpanx='cpanm --local-lib ~/perl5 --metacpan --mirror http://cpan.metacpan.org'
alias df='df -h'
alias du='du -h'
alias grep='grep --color=auto'
alias l='ls -lAtr'
alias l.='ls -ldF .[a-zA-Z0-9]* --color=tty' #only show dotfiles
alias linebreaks="perl -pi -e 's/\r/\n/g'"
alias ll='ls -alhG'
alias ls='ls -G'
alias lsd='ls --group-directories-first'
alias octal_perms='stat -c "%a %n"'
alias penv='perl -MDDP -e "p(%ENV)"'
alias perldoc=cpandoc
alias pine=alpine
alias pretty='python -mjson.tool'
alias ps='ps auxw'
alias redo='sh ~/.fpp/.fpp.sh'
alias source-perlbrew='source ~/perl5/perlbrew/etc/bashrc'
alias ssh-fingerprints='ls ~/.ssh/*.pub | xargs -L 1 ssh-keygen -l -f'
alias stp='git st | fpp'
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

PERL_CPANM_OPT="--local-lib=~/perl5"

# adds $HOME/perl5/bin to PATH
[ $SHLVL -eq 1 ] && eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"

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

function md () { mkdir -p "$@" && cd "$@"; }

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
           BRANCH=$(git rev-parse --abbrev-ref HEAD)
           CURRENT_DIR=${PWD##*/};
           SESSION_NAME="$CURRENT_DIR ⚡ $BRANCH"

           tmux rename-session "$SESSION_NAME"
            ;;
        *)
            $tmux "$@"
            ;;
    esac
}

function fpp() {
    local fpp=$(type -fp fpp)
    $fpp "$@"
    HISTORY_FILE="$HOME/.fpp/.fpp_history"
    FPP_CACHE="$HOME/.fpp/.fpp.sh"
    LAST_COMMAND=`tac $FPP_CACHE |egrep -m 1 . `
    LAST_HISTORY_LINE=$(tac $HISTORY_FILE |egrep -m 1 .)

    if [ "$LAST_COMMAND" != "$LAST_HISTORY_LINE" ] ; then
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
