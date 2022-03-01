#!/usr/bin/env bash

if [[ -d "$HOME/.plenv" ]]; then
    cd "$HOME/.plenv" || exit 1
    git from
    cd - || exit 1
else
    git clone https://github.com/tokuhirom/plenv.git ~/.plenv
fi

# shellcheck source=bash_functions.sh
source ~/.bash_profile
test -e ~/.plenv/plugins/perl-build || git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/

PERL_VERSION=5.34.0

plenv install $PERL_VERSION
plenv global $PERL_VERSION
plenv install-cpanm
plenv rehash

export PATH="$HOME/.plenv/bin:$PATH"
eval "$(plenv init -)"

cpanm --notest App::cpm
plenv rehash

exit 0
