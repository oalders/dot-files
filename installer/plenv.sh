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

MY_PERL_BUILD_DIR="$HOME/.plenv/plugins/perl-build"
if [[ -d $MY_PERL_BUILD_DIR ]]; then
    cd "$MY_PERL_BUILD_DIR" || exit 1
    git from
else
    git clone https://github.com/tokuhirom/Perl-Build.git "$MY_PERL_BUILD_DIR"
fi

PERL_VERSION=5.34.1

plenv install $PERL_VERSION
plenv global $PERL_VERSION
plenv install-cpanm
plenv rehash

export PATH="$HOME/.plenv/bin:$PATH"
eval "$(plenv init -)"

cpanm --notest App::cpm
plenv rehash

exit 0
