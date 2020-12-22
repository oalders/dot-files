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

ok( @{ $e->exports },              'Found some exports' );
ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
is_deeply( $e->imports, [], 'imports' );
ok( !$e->uses_sub_exporter, 'uses_sub_exporter' );
is(
    $e->formatted_import_statement,
    q{use FindBin ();},
    'formatted_import_statement'
);

done_testing();
