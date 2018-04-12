#!/bin/bash

cpm install -g --cpanfile cpan/default.cpanfile
cpm install -g --cpanfile cpan/development.cpanfile
cpm install -g --cpanfile cpan/pause.cpanfile

# Fails to install on OS X
cpanm --notest Data::Printer::Filter::JSON

plenv rehash
