use strict;
use warnings;

use lib 't/lib';

use PerlImports ();
use Test::More import => [qw( done_testing is is_deeply ok subtest )];

# This test demonstrates that we can't handle FindBin
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

done_testing();
