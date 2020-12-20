use strict;
use warnings;

use lib 't/lib';

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

    ok( @{ $e->exports },              'Found some exports' );
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

    ok( @{ $e->exports },             'Found some exports' );
    ok( $e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->imports, [ 'done_testing', 'ok' ], 'imports' );
    ok( !$e->uses_sub_exporter, 'uses_sub_exporter' );
    is(
        $e->formatted_import_statement,
        'use Test::More import => [ qw( done_testing ok ) ];',
        'formatted_import_statement'
    );
};

subtest 'strict' => sub {
    my $e = ImportEditor->new(
        filename    => 't/test-data/foo.t',
        source_text => 'use strict;',
    );
    is(
        $e->module_name(), 'strict',
        'module_name'
    );

    ok( !@{ $e->exports },             'Found some exports' );
    ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->imports, [], 'imports' );
    ok( !$e->uses_sub_exporter, 'uses_sub_exporter' );
    is(
        $e->formatted_import_statement,
        'use strict;',
        'formatted_import_statement'
    );
};

# This test demonstrates that we can't handle FindBin
subtest 'FindBin' => sub {
    my $e = ImportEditor->new(
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
};

subtest 'ViaExporter' => sub {
    my $e = ImportEditor->new(
        filename    => 't/test-data/via-exporter.pl',
        source_text => 'use ViaExporter qw( foo $foo @foo %foo );',
    );
    is(
        $e->module_name(), 'ViaExporter',
        'module_name'
    );

    is_deeply(
        $e->exports, [qw( foo $foo @foo %foo )],
        'Found some exports'
    );
    ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->imports, [qw( $foo %foo @foo foo )], 'imports' );
    ok( !$e->uses_sub_exporter, 'uses_sub_exporter' );
    is(
        $e->formatted_import_statement,
        'use ViaExporter qw( $foo %foo @foo foo );',
        'formatted_import_statement'
    );
};
done_testing();
