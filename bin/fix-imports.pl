#!/usr/bin/env perl

# Does not work with modules using Sub::Exporter

use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

use Path::Tiny qw( path );
use PerlImports ();
use Getopt::Long::Descriptive;

my ( $opt, $usage ) = describe_options(
    'perlimports %o <some-arg>',
    [ 'file|f=s', 'the file containing the imports', { required => 1 } ],
    [ 'read!', 'read STDIN', ],
    [],

    #[ 'verbose|v', "print extra stuff" ],
    [ 'help', "print usage message and exit", { shortcircuit => 1 } ],
);

print( $usage->text ), exit if $opt->help;

my $input;

if ( $opt->read ) {
    local $/;
    $input = <STDIN>;
}
else {
    $input = path( $opt->file )->slurp;
}

my $doc = PPI::Document->new( \$input );

my $includes = $doc->find(
    sub {
        $_[1]->isa('PPI::Statement::Include');
    }
);

foreach my $include ( @{$includes} ) {
    my $e = PerlImports->new(
        filename => $opt->file,
        include  => $include,
    );

    my $elem = $e->formatted_import_statement;

    # https://github.com/adamkennedy/PPI/issues/189
    $include->insert_before( $elem->clone );
    $include->remove;
}

if ( $opt->read ) {
    print "$doc";
}
else {
    path( $opt->file )->spew($doc);
}

exit(0);
