#!/usr/bin/env perl

# Does not work with modules using Sub::Exporter

use strict;
use warnings;

use Data::Printer;
use List::AllUtils qw( any uniq );
use Module::Runtime qw( require_module );
use Path::Tiny qw( path );

my $filename = shift @ARGV;
if ( !$filename ) {
    print STDERR 'File name not passed as first arg';
    exit(1);
}

my $input = <STDIN>;

my ($module);

if ( $input =~ m{use ([\w:]+)} ) {
    $module = $1;
}
else {
    print $input;
    exit(0);
}

require_module($module);
$module->import;

## no critic (TestingAndDebugging::ProhibitNoStrict)
no strict 'refs';
my @imports
    = uniq( @{ $module . '::EXPORT' }, @{ $module . '::EXPORT_OK' } );
my $test_builder
    = any { $_ eq 'Test::Builder::Module' } @{ $module . '::ISA' };
use strict;
## use critic

my @found;

my $content = path($filename)->slurp;
for my $symbol (@imports) {
    $symbol =~ s{\A&}{};
    if ( $content =~ m{\Q$symbol\E} ) {
        push @found, $symbol;
    }
}

if (@found) {

    my $template
        = $test_builder
        ? 'use %s import => [ qw( %s ) ];'
        : 'use %s qw( %s );';

    my $statement = sprintf( $template, $module, join q{ }, sort @found );

    # Don't deal with Test::Builder classes here to keep is simple for now
    if ( length($statement) > 78 && !$test_builder ) {
        $statement = sprintf( "use %s qw(\n", $module );
        for (@found) {
            $statement .= "    $_\n";
        }
        $statement .= ");\n";
    }
    print $statement;
}
else {
    printf( 'use %s ();', $module );
}
