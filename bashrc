alias ll='ls -alhG'
alias perldoc=cpandoc
alias pine=alpine
alias cpanx='cpanm --mirror http://cpan.metacpan.org'
alias l.='ls -ldF .[a-zA-Z0-9]* --color=tty' #only show dotfiles
alias ps='ps auxw'
alias du='du -h'
alias df='df -h'

if [ -f /home/`whoami`/perl5/perlbrew/etc/bashrc ]; then
   . /home/`whoami`/perl5/perlbrew/etc/bashrc
fi

