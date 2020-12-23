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

my $input = shift @ARGV || join q{}, <STDIN>;

my $doc = PPI::Document->new( \$input );

my $includes = $doc->find(
    sub {
        $_[1]->isa('PPI::Statement::Include');
    }
);

foreach my $include (@{$includes}) {
    my $e = PerlImports->new(
        filename    => $filename,
        include     => $include,
    );
}

print "$doc";

exit(0);
