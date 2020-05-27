#!/bin/bash

# On OSX plenv will have been installed via homebrew

if [ "$IS_DARWIN" != true ]; then
    test -e ~/.plenv || git clone https://github.com/tokuhirom/plenv.git ~/.plenv

    # shellcheck source=bash_functions.sh
    source ~/.bash_profile
    test -e ~/.plenv/plugins/perl-build || git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
fi

PERL_VERSION=5.30.2

plenv install $PERL_VERSION
plenv global $PERL_VERSION
plenv install-cpanm
plenv rehash

export PATH="$HOME/.plenv/bin:$PATH"
eval "$(plenv init -)"

cpanm --notest App::cpm
plenv rehash

exit 0
