#!/usr/bin/env perl

# Does not work with modules using Sub::Exporter

use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

use ImportEditor ();

my $filename = shift @ARGV;
if ( !$filename ) {
    print STDERR 'File name not passed as first arg';
    exit(1);
}

my $input = shift @ARGV || <STDIN>;

my $e = ImportEditor->new( filename => $filename, source_text => $input );

if (!$e->module_name) {
    print $input;
    exit(0);
}


my @found = @{$e->imports};

if ( !@found ) {
    if ( $e->uses_sub_exporter ) {
        print( $input . ' # uses Sub::Exporter' );
        exit(0);
    }
}

print $e->formatted_import_statement;
