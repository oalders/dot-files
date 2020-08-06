#!/usr/bin/env bash

# shellcheck disable=SC2038
find cpan/* | xargs -n 1 cpm install -g --cpanfile

plenv rehash
