use strict;
use warnings;

use lib 't/lib';

use PerlImports ();
use Test::More import => [qw( diag done_testing is is_deeply ok )];

my $e = PerlImports->new(
    filename    => 't/test-data/exported-variables.pl',
    source_text => 'use ViaExporter qw();',
);

is( $e->module_name(), 'ViaExporter', 'module_name' );

is_deeply(
    $e->exports,
    [
        'foo',
        '$foo',
        '@foo',
        '%foo',
    ],
    'some exports'
);
ok( !$e->is_noop, 'is_noop' );
is_deeply( $e->imports, [ '%foo', '@foo' ], 'imports' );
is(
    $e->formatted_import_statement,
    q{use ViaExporter qw( %foo @foo );},
    'formatted_import_statement'
);

done_testing();
