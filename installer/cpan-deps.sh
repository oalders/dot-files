#!/usr/bin/env bash

set -eux

# https://stackoverflow.com/questions/67003619/mac-m1-homebrew-perl-carton-netssleay-is-loading-libcrypto-in-an-unsafe-way
cpm install ExtUtils::MakeMaker

# shellcheck disable=SC2038
find cpan/* | xargs -n 1 cpm install -g --cpanfile

if is there plenv; then
    plenv rehash
fi
