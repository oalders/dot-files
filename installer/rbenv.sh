#!/usr/bin/env bash

set -eu -o pipefail
version=3.3.5

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

if is os name eq darwin; then
    if ! is there rbenv; then
        brew install rbenv
    fi
elif is os name eq linux; then
    if [[ -d "$HOME/.rbenv/.git" ]]; then
        cd "$HOME/.rbenv" || exit 1
        git from
        cd - || exit 1
    else
        rm -rf "$HOME/.rbenv"
        git clone --depth 1 https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
    fi

    ruby_build_dir="$HOME/.rbenv/plugins/ruby-build"
    if [[ -d $ruby_build_dir/.git ]]; then
        cd "$ruby_build_dir" || exit 1
        git from
        cd - || exit 1
    else
        git clone --depth 1 https://github.com/rbenv/ruby-build.git "$ruby_build_dir"
    fi

    add_path "$HOME/.rbenv/bin"

    if [[ $IS_SUDOER == true ]] && is there apt; then
        # Build deps ruby-build needs to compile Ruby from source.
        sudo apt-get install -y -q --no-install-recommends \
            libffi-dev \
            libreadline-dev \
            libssl-dev \
            libyaml-dev \
            zlib1g-dev
    fi
else
    exit 0
fi

# Might need to initialize rbenv in the shell
if ! is var RBENV_SHELL set; then
    eval "$(rbenv init - bash)"
fi

if is cli output stdout rbenv --arg version like "^$version\b"; then
    echo "Ruby version $version is already installed"
    exit
fi

if ! is cli output stdout rbenv --arg versions like "\b$version\b" --debug; then
    rbenv install $version
fi

rbenv global $version

if ! is cli version ruby eq $version; then
    echo "Ruby version $version is not available"
fi
