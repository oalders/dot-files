#!/bin/bash

cpanm --installdeps --cpanfile cpan/default.cpanfile .
cpanm --installdeps --cpanfile cpan/development.cpanfile .
cpanm --installdeps --cpanfile cpan/pause.cpanfile .
cpanm --installdeps --cpanfile cpan/OALDERS.cpanfile .

# Fails to install on OS X
cpanm --notest Data::Printer::Filter::JSON

#cpm install --cpanfile cpan/default.cpanfile
#cpm install --cpanfile cpan/development.cpanfile
#cpm install --cpanfile cpan/pause.cpanfile
