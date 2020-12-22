use strict;
use warnings;

use lib 't/lib';

use PerlImports ();
use Test::More import => [ qw( done_testing is is_deeply ok ) ];

my $e = PerlImports->new(
    filename    => 't/lib/UsesMoo.pm',
    source_text => 'use Moo;',
);
is(
    $e->module_name(), 'Moo',
    'module_name'
);

is_deeply( $e->exports, [], 'exports' );
ok( $e->is_noop, 'is_noop' );
is_deeply( $e->imports, [], 'imports' );
is(
    $e->formatted_import_statement,
    q{use Moo;},
    'formatted_import_statement'
);

done_testing();
