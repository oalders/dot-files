alias ll='ls -alhG'
alias perldoc=cpandoc
alias pine=alpine
alias cpanx=cpanm --mirror http://cpan.metacpan.org

if [ -f /home/`whoami`/perl5/perlbrew/etc/bashrc ]; then
   . /home/`whoami`/perl5/perlbrew/etc/bashrc
fi
