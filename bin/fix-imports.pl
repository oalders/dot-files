#!/usr/bin/env perl

# Does not work with modules using Sub::Exporter

use strict;
use warnings;

use List::AllUtils qw( any uniq );
use Module::Runtime qw( module_notional_filename require_module );
use Path::Tiny qw( path );
use PPI ();

my $filename = shift @ARGV;
if ( !$filename ) {
    print STDERR 'File name not passed as first arg';
    exit(1);
}

my $input = shift @ARGV || <STDIN>;

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

my @found = find_used_imports( $filename, \@imports );

sub find_used_imports {
    my $filename = shift;
    my $imports  = shift;

    my $content = path($filename)->slurp;
    my $doc     = PPI::Document->new( \$content );

    my %imports = map { $_ => 1 } @imports;

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    my %found;
    for my $word (
        @{
            $doc->find(
                sub {
                    $_[1]->isa('PPI::Token::Word')
                        || ( $_[1]->isa('PPI::Token::Symbol')
                        && $_[1]->symbol_type eq '&' );
                }
                )
                || []
        }
    ) {
        if ( $word->isa('PPI::Token::Symbol') ) {
            $word =~ s{^&}{};
        }
        if ( exists $imports{"$word"} ) {
            $found{"$word"}++;
        }
        my @found = sort { $a cmp $b } keys %found;
    }

    my @found = sort { $a cmp $b } keys %found;
    return @found;
}

if ( !@found ) {
    if ( _uses_sub_exporter($module) ) {
        print( $input . ' # uses Sub::Exporter' );
        exit(0);
    }
}

if ( !@found ) {
    printf( 'use %s (); # @EXPORT[_OK] is empty', $module );
    exit(0);
}

my $template
    = $test_builder
    ? 'use %s import => [ qw( %s ) ];'
    : 'use %s qw( %s );';

my $statement = sprintf( $template, $module, join q{ }, @found );

# Don't deal with Test::Builder classes here to keep is simple for now
if ( length($statement) > 78 && !$test_builder ) {
    $statement = sprintf( "use %s qw(\n", $module );
    for (@found) {
        $statement .= "    $_\n";
    }
    $statement .= ");\n";
}
print $statement;

# Stolen from Open::This
sub _maybe_find_local_module {
    my $module        = shift;
    my $possible_name = module_notional_filename($module);
    print "possible $possible_name\n";
    my @dirs
        = exists $ENV{OPEN_THIS_LIBS}
        ? split m{,}, $ENV{OPEN_THIS_LIBS}
        : ( 'lib', 't/lib' );

    for my $dir (@dirs) {
        my $path = path( $dir, $possible_name );
        if ( $path->is_file ) {
            return "$path";
        }
    }
    return undef;
}

# Stolen from Open::This
sub _maybe_find_installed_module {
    my $module = shift;

    # This is a loadable module.  Have this come after the local module checks
    # so that we don't default to installed modules.
    return Module::Util::find_installed($module);
}

sub _uses_sub_exporter {
    my $module   = shift;
    my $filename = _maybe_find_local_module($module)
        || _maybe_find_installed_module($filename);

    if ( !$filename ) {
        print "Cannot find $filename\n";
        return;
    }

    my $content = path($filename)->slurp;
    my $doc     = PPI::Document->new( \$content );

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    my $include_statements
        = $doc->find(
        sub { $_[1]->isa('PPI::Statement::Include') && !$_[1]->pragma } )
        || [];
    for my $st (@$include_statements) {
        next if $st->schild(0) eq 'no';

        my $included_module = $st->schild(1);
        return 1 if $included_module eq 'Sub::Exporter';
    }
    return 0;
}
