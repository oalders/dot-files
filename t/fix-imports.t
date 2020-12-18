use strict;
use warnings;

use ImportEditor ();
use Test::More import => [ qw( done_testing is is_deeply ok subtest ) ];

subtest 'Getopt::Long' => sub {
    my $e = ImportEditor->new(
        filename    => 't/test-data/foo.pl',
        source_text => 'use Getopt::Long;',
    );
    is(
        $e->module_name(), 'Getopt::Long',
        'module_name'
    );

    ok( @{ $e->exports },              'Found some imports' );
    ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->imports, ['GetOptions'], 'imports' );
    ok( !$e->uses_sub_exporter, 'uses_sub_exporter' );
    is(
        $e->formatted_import_statement, 'use Getopt::Long qw( GetOptions );',
        'formatted_import_statement'
    );
};

subtest 'Test::More' => sub {
    my $e = ImportEditor->new(
        filename    => 't/test-data/foo.t',
        source_text => 'use Test::More;',
    );
    is(
        $e->module_name(), 'Test::More',
        'module_name'
    );

    ok( @{ $e->exports },             'Found some imports' );
    ok( $e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->imports, [ 'done_testing', 'ok' ], 'imports' );
    ok( !$e->uses_sub_exporter, 'uses_sub_exporter' );
    is(
        $e->formatted_import_statement,
        'use Test::More import => [ qw( done_testing ok ) ];',
        'formatted_import_statement'
    );
};

done_testing();
