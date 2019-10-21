#!/bin/bash

# On OSX plenv will have been installed via homebrew

test -e ~/.plenv || git clone https://github.com/tokuhirom/plenv.git ~/.plenv
source ~/.bash_profile
test -e ~/.plenv/plugins/perl-build || git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/

PERL_VERSION=5.30.0

plenv install $PERL_VERSION
plenv global $PERL_VERSION
plenv install-cpanm
plenv rehash

export PATH="$HOME/.plenv/bin:$PATH"
eval "$(plenv init -)"

cpanm --notest App::cpm
plenv rehash
