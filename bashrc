alias ll='ls -alhG'
alias perldoc=cpandoc
alias pine=alpine
alias cpanx='cpanm --local-lib ~/perl5 --metacpan --mirror http://cpan.metacpan.org'
alias cpanw='cpanm --local-lib ~/perl5 --mirror http://10.0.0.79/minicpan'
alias l.='ls -ldF .[a-zA-Z0-9]* --color=tty' #only show dotfiles
alias ps='ps auxw'
alias du='du -h'
alias df='df -h'

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
