#!/bin/bash

# On OSX plenv will have been installed via homebrew

plenv install 5.26.1
plenv global 5.26.1
plenv install-cpanm
plenv rehash

export PATH="$HOME/.plenv/bin:$PATH"
eval "$(plenv init -)"

cpanm App::cpm
plenv rehash
