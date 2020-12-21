#!/usr/bin/env perl

# Does not work with modules using Sub::Exporter

use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

use PerlImports ();

my $filename = shift @ARGV;
if ( !$filename ) {
    print STDERR 'File name not passed as first arg';
    exit(1);
}

my $input = shift @ARGV || <STDIN>;

my $e = PerlImports->new( filename => $filename, source_text => $input );

print $e->formatted_import_statement;
exit(0);
