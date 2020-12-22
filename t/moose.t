use strict;
use warnings;

use lib 't/lib';

use PerlImports ();
use Test::More import => [ qw( done_testing is is_deeply ok ) ];

my $e = PerlImports->new(
    filename    => 't/lib/UsesMoose.pm',
    source_text => 'use Moose;',
);
is(
    $e->module_name(), 'Moose',
    'module_name'
);

is_deeply( $e->exports, [], 'Found some exports' );
ok( $e->is_noop, 'is_noop' );
is_deeply( $e->imports, [], 'imports' );
is(
    $e->formatted_import_statement,
    q{use Moose;},
    'formatted_import_statement'
);

done_testing();
