export EDITOR=vim

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignoredups

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

alias batterylife='pmset -g batt | grep Internal | awk "{print $2}" | sed "s/;//"'
alias bytes_human='perl -MNumber::Bytes::Human -e "print Number::Bytes::Human::format_bytes shift"'
alias cpanx='cpanm --local-lib ~/perl5 --metacpan --mirror http://cpan.metacpan.org'
alias df='df -h'
alias du='du -h'
alias grep='grep --color=auto'
alias l.='ls -ldF .[a-zA-Z0-9]* --color=tty' #only show dotfiles
alias linebreaks="perl -pi -e 's/\r/\n/g'"
alias ll='ls -alhG'
alias ls='ls -G'
alias lsd='ls --group-directories-first'
alias octal_perms='stat -c "%a %n"'
alias penv='perl -MDDP -e "p(%ENV)"'
alias perldoc=cpandoc
alias pine=alpine
alias ps='ps auxw'
alias ssh-fingerprints='ls ~/.ssh/*.pub | xargs -L 1 ssh-keygen -l -f'
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

if [ -f "$HOME/perl5/perlbrew/etc/bashrc" ]; then
   . "$HOME/perl5/perlbrew/etc/bashrc"
fi

if [ -d "$HOME/local/bin" ] ; then
    PATH="$HOME/local/bin:$PATH"
fi

PERL_CPANM_OPT="--local-lib=~/perl5"

function gpull(){
    git pull origin $1;
    gsubs;
}

function grebase(){
    git pull --rebase origin $1;
    gsubs;
}

function gsubs(){
    STARTDIR=`pwd`;
    cd $(git rev-parse --show-toplevel);
    git submodule init;
    git submodule update;
    cd $STARTDIR;
}

function gpush(){
    grebase;
    git push origin $1;
}

RED="\[\033[0;31m\]"
YELLOW="\[\033[0;33m\]"
GREEN="\[\033[0;32m\]"
BLUE="\[\033[0;34m\]"
LIGHT_RED="\[\033[0;31m\]"
LIGHT_GREEN="\[\033[0;32m\]"
WHITE="\[\033[0;37m\]"
WHITE='\e[0;37m'
LIGHT_GRAY="\[\033[0;37m\]"
COLOR_NONE="\[\e[0m\]"

function parse_git_branch {

  #git rev-parse --git-dir &> /dev/null
  git_status="$(git status 2> /dev/null)"
  branch_pattern="^# On branch ([^${IFS}]*)"
  remote_pattern="# Your branch is (.*) of"
  diverge_pattern="# Your branch and (.*) have diverged"
  if [[ ! ${git_status} =~ "working directory clean" ]]; then
    state=""
  fi
  # add an else if or two here if you want to get more specific
  if [[ ${git_status} =~ ${remote_pattern} ]]; then
    if [[ ${BASH_REMATCH[1]} == "ahead" ]]; then
      remote="${YELLOW}↑"
    else
      remote="${YELLOW}↓"
    fi
  fi
  if [[ ${git_status} =~ ${diverge_pattern} ]]; then
    remote="${YELLOW}↕"
  fi
  if [[ ${git_status} =~ ${branch_pattern} ]]; then
    branch=${BASH_REMATCH[1]}
    echo " (${branch})${remote}${state}"
  fi
}

function prompt_func() {
    HOSTNAME=`hostname`

    # this kills performance in the Rackspace cloud
    if [ "$HOSTNAME" = "bacchus" ]
    then
        return
        git_branch="$(git branch 2> /dev/null)"
        branch_pattern="* (.*)"
        if [[ ${git_status} =~ ${branch_pattern} ]]; then
            branch=${BASH_REMATCH[1]}
            echo " (${branch})"
            return
        fi
    fi

    SHELL_COLOR=$BLUE;
    previous_return_value=$?;
    prompt="${TITLEBAR}${SHELL_COLOR}[${COLOR_NONE}\w${LIGHT_GRAY}$(parse_git_branch)${SHELL_COLOR}]${COLOR_NONE} "
    if test $previous_return_value -eq 0
    then
        PS1="${prompt}$ "
    else
        PS1="${prompt}${RED}${COLOR_NONE}$ "
    fi
}

function whosonport {
    sudo lsof -i :$1;
}

function check_compression {
      curl -I -H 'Accept-Encoding: gzip,deflate' $1 |grep "Content-Encoding"
}

function trace_process {
    sudo lsof -p $1 && sudo strace -fp $1
}

function metacpan-pp {
    curl -s  https://metacpan.org/author/OALDERS | perl -ne 'if (m!class="release".*/release/([^"]+)!) { $_ = $1; s/-/::/g; print $_,$/ }' | sort
}

function git-recover-file {
    git checkout $(git rev-list -n 1 HEAD -- "$1")^ -- "$1"
}

PROMPT_COMMAND=prompt_func

if [ -f /etc/bash_completion.d/git ]; then
    source /etc/bash_completion.d/git
elif [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
fi

if [ -d ~/perl5/bin ]; then
    export PATH=~/perl5/bin:$PATH
fi

if ! type "ack" > /dev/null  2>&1; then
    if type 'ack-grep' > /dev/null 2>&1; then
        alias ack='ack-grep'
    fi
fi
