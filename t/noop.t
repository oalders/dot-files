use strict;
use warnings;

use lib 't/lib';

use PerlImports ();
use Test::More import => [ qw( diag done_testing is ok subtest ) ];

subtest 'Types::Standard' => sub {
    my $e = PerlImports->new(
        filename    => 'lib/PerlImports.pm',
        source_text => 'use Types::Standard;',
    );
    is(
        $e->module_name, 'Types::Standard',
        'module_name'
    );
    ok( $e->is_noop, 'noop' );
};

subtest 'Test::RequiresInternet' => sub {
    my $e = PerlImports->new(
        filename    => 't/test-data/noop.t',
        source_text =>
            q{use Test::RequiresInternet ('www.example.com' => 80 );},
    );
    is(
        $e->module_name, 'Test::RequiresInternet',
        'module_name'
    );

    # This is not currently treated as a noop, since we have imports. We just
    # don't know what can be exported. It will basically pass through without
    # changes, though.
    ok( !$e->is_noop, 'noop' );
    is(
        $e->formatted_import_statement,
        q{use Test::RequiresInternet ('www.example.com' => 80 );}
    );
};

done_testing();
