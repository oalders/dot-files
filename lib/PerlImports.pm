package PerlImports;

# Does not work with modules using Sub::Exporter

use Moo;

use List::AllUtils qw( any uniq );
use Module::Runtime qw( module_notional_filename require_module );
use Module::Util qw( find_installed );
use Path::Tiny qw( path );
use PPI::Document ();
use Types::Standard qw(ArrayRef Bool Maybe Str);

has exports => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_exports',
);

has _filename => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'filename',
    required => 1,
);

has imports => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_imports',
);

has is_noop => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_noop',
);

has _isa_test_builder_module => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build__isa_test_builder_module',
);

has module_name => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    builder => '_build_module_name',
);

has _source_text => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'source_text',
    required => 1,
);

has uses_sub_exporter => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_uses_sub_exporter',
);

sub _build_module_name {
    my $self = shift;

    if ( $self->_source_text =~ m{use ([\w:]+)} ) {
        return $1;
    }

    return undef;
}

sub _build_exports {
    my $self   = shift;
    my $module = $self->module_name;
    require_module($module);
    $module->import;

## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my @exports
        = uniq( @{ $module . '::EXPORT' }, @{ $module . '::EXPORT_OK' } );
    use strict;
## use critic

    # Moose Type library? And yes, private method bad.
    if ( !@exports && require_module('Class::Inspector') ) {
        if (
            any { $_ eq 'MooseX::Types::Combine::_provided_types' }
            @{ Class::Inspector->methods(
                    $self->module_name, 'full', 'private'
                )
            }
        ) {
            my %types = $self->module_name->_provided_types;
            @exports = keys %types;
        }
    }

    return \@exports;
}

sub _build__isa_test_builder_module {
    my $self = shift;
    $self->exports;    # ensure module has already been required

## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my $_isa_test_builder = any { $_ eq 'Test::Builder::Module' }
    @{ $self->module_name . '::ISA' };
    use strict;
## use critic

    return $_isa_test_builder;
}

sub _build_imports {
    my $self = shift;

    my $content = path( $self->_filename )->slurp;
    my $doc     = PPI::Document->new( \$content );

    my %exports = map { $_ => 1 } @{ $self->exports };

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    my %found;
    for my $word (
        @{
            $doc->find(
                sub {
                    $_[1]->isa('PPI::Token::Word')
                        || $_[1]->isa('PPI::Token::Symbol');
                }
                )
                || []
        }
    ) {
        if ( $word->isa('PPI::Token::Symbol') ) {
            $word =~ s{^&}{};
        }

        # Getopt::Long exports &GetOptions
        if ( exists $exports{"$word"} || exists $exports{ '&' . "$word" } ) {
            $found{"$word"}++;
        }
        my @found = sort { $a cmp $b } keys %found;
    }

    my @found = sort { $a cmp $b } keys %found;
    return \@found;
}

sub _build_is_noop {
    my $self = shift;

    return 0 if @{ $self->imports };

    my %noop = (
        'Types::Standard' => 1,
    );

    return 1 if exists $noop{ $self->module_name };

    # Is it a pragma?
    return 1 if lc( $self->module_name ) eq $self->module_name;

    return 1 if $self->uses_sub_exporter;

    # This should catch Moose classes
    if (   require_module('Moose::Util')
        && Moose::Util::find_meta( $self->module_name ) ) {
        return 1;
    }

    # This should catch Moo classes
    if ( require_module('Class::Inspector') ) {
        return 1
            if any { $_ eq 'Moo::is_class' }
        @{ Class::Inspector->methods( $self->module_name, 'full', 'public' )
        };
    }

    return 0;
}

sub formatted_import_statement {
    my $self = shift;

    if ( $self->is_noop || !@{ $self->exports } ) {
        return $self->_source_text;
    }

    if ( !@{ $self->imports } ) {
        return sprintf( 'use %s ();', $self->module_name );
    }

    my $template
        = $self->_isa_test_builder_module
        ? 'use %s import => [ qw( %s ) ];'
        : 'use %s qw( %s );';

    my $statement = sprintf(
        $template, $self->module_name, join q{ },
        @{ $self->imports }
    );

    # Don't deal with Test::Builder classes here to keep is simple for now
    if ( length($statement) > 78 && !$self->_isa_test_builder_module ) {
        $statement = sprintf( "use %s qw(\n", $self->module_name );
        for ( @{ $self->imports } ) {
            $statement .= "    $_\n";
        }
        $statement .= ");";
    }
    return $statement;
}

# Stolen from Open::This
sub _maybe_find_local_module {
    my $self          = shift;
    my $module        = $self->module_name;
    my $possible_name = module_notional_filename($module);
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
    my $self = shift;

    # This is a loadable module.  Have this come after the local module checks
    # so that we don't default to installed modules.
    return find_installed( $self->module_name );
}

sub _build_uses_sub_exporter {
    my $self     = shift;
    my $module   = $self->module_name;
    my $filename = $self->_maybe_find_local_module
        || $self->_maybe_find_installed_module;

    if ( !$filename ) {
        print "Cannot find $module\n";
        return;
    }

    my $content = path($filename)->slurp;
    my $doc     = PPI::Document->new( \$content );

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    my $include_statements = $doc->find(
        sub {
            $_[1]->isa('PPI::Statement::Include') && !$_[1]->pragma;
        }
    ) || [];
    for my $st (@$include_statements) {
        next if $st->schild(0) eq 'no';

        my $included_module = $st->schild(1);
        if ( $included_module eq 'Sub::Exporter' ) {
            return 1;
        }
    }
    return 0;
}

1;
