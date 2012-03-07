alias ll='ls -alhG'
alias perldoc=cpandoc
alias pine=alpine
alias cpanx='cpanm --local-lib ~/perl5 --metacpan --mirror http://cpan.metacpan.org'
alias cpanw='cpanm --local-lib ~/perl5 --mirror http://10.0.0.79/minicpan'
alias l.='ls -ldF .[a-zA-Z0-9]* --color=tty' #only show dotfiles
alias lsd='ls --group-directories-first'
alias ps='ps auxw'
alias du='du -h'
alias df='df -h'
alias ssh-fingerprints='ls ~/.ssh/*.pub | xargs -L 1 ssh-keygen -l -f'
alias xpasswd='perl -MCrypt::XkcdPassword -E "say Crypt::XkcdPassword->make_password"'
alias xkcdalt='perl -MWWW::xkcd -E "say WWW::xkcd->new->fetch_metadata->{alt}"'

if [ -f /home/`whoami`/perl5/perlbrew/etc/bashrc ]; then
   . /home/`whoami`/perl5/perlbrew/etc/bashrc
fi

if [ -d "$HOME/local/bin" ] ; then
    PATH="$HOME/local/bin:$PATH"
fi

PERL_CPANM_OPT="--local-lib=~/perl5"

function gpull(){
    STARTDIR=`pwd`;
    git pull origin $1;
    cd $(git rev-parse --show-toplevel);
    git submodule init;
    git submodule update;
    cd $STARTDIR;
}

function gpush(){
    gpull $1;
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

  git rev-parse --git-dir &> /dev/null
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
    case $HOSTNAME in
        "escher") SHELL_COLOR=$YELLOW ;;
        "bach") SHELL_COLOR=$LIGHT_GREEN ;;
        "dell") SHELL_COLOR=$RED ;;
        "bacchus") SHELL_COLOR=$BLUE ;;
    esac

    previous_return_value=$?;
    # prompt="${TITLEBAR}$BLUE[$RED\w$GREEN$(__git_ps1)$YELLOW$(git_dirty_flag)$BLUE]$COLOR_NONE "
    prompt="${TITLEBAR}${SHELL_COLOR}[${COLOR_NONE}\w${LIGHT_GRAY}$(parse_git_branch)${SHELL_COLOR}]${COLOR_NONE} "
    if test $previous_return_value -eq 0
    then
        PS1="${prompt}$ "
    else
        PS1="${prompt}${RED}${COLOR_NONE}$ "
    fi
}

PROMPT_COMMAND=prompt_func

if [ -f /etc/bash_completion.d/git ]; then
    source /etc/bash_completion.d/git
fi

