#!/usr/bin/env bash

if [[ -d "$HOME/.plenv/.git" ]]; then
    cd "$HOME/.plenv" || exit 1
    git from
    cd - || exit 1
else
    # Might be an older install not using a Git checkout
    rm -rf "$HOME/.plenv"
    git clone https://github.com/tokuhirom/plenv.git ~/.plenv
fi

# shellcheck source=bash_functions.sh
source ~/.bash_profile

my_perl_build_dir="$HOME/.plenv/plugins/perl-build"
if [[ -d $my_perl_build_dir ]]; then
    cd "$my_perl_build_dir" || exit 1
    git from
else
    git clone https://github.com/tokuhirom/Perl-Build.git "$my_perl_build_dir"
fi

perl_version=5.42.0

plenv install $perl_version
plenv global $perl_version
plenv install-cpanm
plenv rehash

add_path "$HOME/.plenv/bin"
eval "$(plenv init -)"

cpanm --notest App::cpm
plenv rehash

exit 0
