#!/bin/bash

cpm install --cpanfile cpan/default.cpanfile
cpm install --cpanfile cpan/development.cpanfile
cpm install --cpanfile cpan/pause.cpanfile

# Fails to install on OS X
cpanm --notest Data::Printer::Filter::JSON
