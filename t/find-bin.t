use strict;
use warnings;

use lib 't/lib';

use PerlImports ();
use Test::More import => [ qw( done_testing is is_deeply ok ) ];

# This test demonstrates that we can't handle FindBin
my $e = PerlImports->new(
    filename    => 't/test-data/find-bin.pl',
    source_text => 'use FindBin qw( $Bin );',
);
is(
    $e->module_name(), 'FindBin',
    'module_name'
);

ok( $e->is_noop, 'noop' );
is(
    $e->formatted_import_statement,
    q{use FindBin qw( $Bin );},
    'formatted_import_statement'
);

done_testing();
