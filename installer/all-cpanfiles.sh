#!/bin/bash

find cpan/*cpanfile | xargs -n 1 cpm install -g --verbose --show-build-log-on-failure --cpanfile
