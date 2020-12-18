#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use List::AllUtils qw( uniq );
use Module::Runtime qw( require_module );
use Path::Tiny qw( path );

my $filename = shift @ARGV;
if ( !$filename ) {
    print STDERR 'File name not passed as first arg';
    exit(1);
}

my $input = <STDIN>;

my ($module);

if ( $input =~ m{use ([\w:]+)} ) {
    $module = $1;
}
else {
    print $input;
    exit(0);
}

require_module($module);
$module->import;

## no critic (TestingAndDebugging::ProhibitNoStrict)
no strict 'refs';
my @imports
    = uniq( @{ $module . '::EXPORT' }, @{ $module . '::EXPORT_OK' } );
use strict;
## use critic

my @found;

my $content = path($filename)->slurp;
for my $symbol (@imports) {
    $symbol =~ s{\A&}{};
    if ( $content =~ m{$symbol} ) {
        push @found, $symbol;
    }
}

printf( 'use %s qw( %s );', $module, join q{ }, sort @found );
