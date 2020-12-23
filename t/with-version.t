use strict;
use warnings;

use lib 't/lib';

use PerlImports ();
use Test::More import => [ qw( diag done_testing is is_deeply ok ) ];

my $e = PerlImports->new(
    filename    => 't/test-data/with-version.pl',
    source_text => 'use Getopt::Long 2.40 qw();',
);
is(
    $e->module_name(), 'Getopt::Long',
    'module_name'
);

use DDP;
ok( @{$e->exports}, 'some exports' );
ok( !$e->is_noop, 'is_noop' );
is_deeply( $e->imports, ['GetOptions'], 'imports' );
is(
    $e->formatted_import_statement,
    q{use Getopt::Long 2.40 qw( GetOptions );},
    'formatted_import_statement'
);

done_testing();
