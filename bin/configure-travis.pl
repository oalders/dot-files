use strict;
use warnings;
use feature qw( say );

use Data::Dumper;
use Data::Printer;
use List::MoreUtils qw( first_index indexes );
use List::Util qw ( any none uniq );
use Ref::Util qw( is_plain_arrayref );
use Term::Choose qw( choose );
use YAML::Tiny qw( DumpFile LoadFile );

$Data::Dumper::Sortkeys = 1;

my $config_file = '.travis.yml';
my $config      = LoadFile($config_file);
$config->{sudo} = 'false' unless exists $config->{sudo};

my @perl_versions = qw(
    5.10
    5.12
    5.14
    5.16
    5.18
    5.20
    5.22
    5.24
    5.26
    5.28
);

unless ( exists $config->{cache}->{directories} ) {
    $config->{cache}{directories} = ['~/perl5'];
}

my $is_perl = exists $config->{language} && $config->{language} eq 'perl';
my $perl_helpers;
if (
    $config->{language} eq 'perl' && ( !exists $config->{before_install} )
    || (
        none {
            $_ eq 'eval $(curl https://travis-perl.github.io/init) --auto'
        }
        @{ $config->{before_install} }
    )
) {
    say <<'EOF';
Enable automatic Perl helpers by adding the following to "before_install":

    eval $(curl https://travis-perl.github.io/init) --auto

EOF
}

if ( exists $config->{before_install}
    && is_plain_arrayref( $config->{before_install} ) ) {
    $perl_helpers
        = any { $_ =~ m{travis-perl} } @{ $config->{before_install} };
}

{
    no autovivification;

    my $apt_pkgs
        = exists $config->{addons}->{apt}->{packages}
        ? $config->{addons}->{apt}->{packages}
        : [];

    my $msg = <<'EOF';
Would you like to install any of the following apt pkgs?

* select and unselect using the space bar
* ctrl-d to exit without selecting
EOF

    say $msg;

    my @choices
        = sort { $a cmp $b }
        uniq( 'aspell', 'aspell-en', 'elasticsearch', @{$apt_pkgs} );
    my @pre_selected;
    for my $choice (@choices) {
        push @pre_selected,
            grep { $_ > -1 } first_index { $_ eq $choice } @{$apt_pkgs};
    }

    my @selected = choose(
        \@choices,
        { mark => \@pre_selected }
    );

    if (@selected) {
        $config->{addons}{apt}{packages} = \@selected;
    }
    elsif ( exists $config->{addons}{apt}{packages} ) {
        delete $config->{addons}{apt}{packages};
    }
}

# Maybe add a test coverage run to the matrix
{
    no autovivification;
    if ($perl_helpers) {
        my $coverage_version;
        say 'Enable coverage reports?';
        my $enable = choose( [ 'true', 'false' ] );
        my @includes
            = exists $config->{matrix}{include}
            ? @{ $config->{matrix}{include} }
            : ();

        if ( $enable eq 'true' ) {

            use autovivification;

            # get highest Perl release version
            for my $version ( reverse @perl_versions ) {
                if ( any { $_ eq $version } @{ $config->{perl} } ) {
                    $coverage_version
                        = { perl => $version, env => 'COVERAGE=1' };
                    unless (
                        list_contains_hash(
                            \@includes,
                            $coverage_version
                        )
                    ) {

                        push @includes,
                            { perl => $version, env => 'COVERAGE=1' };
                    }
                    last;
                }
            }
            $config->{matrix}{include} = \@includes;
        }
    }
}

if ( $config->{perl} ) {
    my %perls = map { $_ => 1 } @{ $config->{perl} };
    for my $version (@perl_versions) {
        $perls{$version} = 1;
    }
    $config->{perl} = [ sort keys %perls ];
    my @allowed
        = exists $config->{matrix}{allow_failures}
        ? @{ $config->{matrix}{allow_failures} }
        : ();

    for my $might_fail ( 'blead', 'dev' ) {
        if ( exists $perls{$might_fail} ) {
            if (
                none { exists $_->{perl} && $_->{perl} eq $might_fail }
                @allowed
            ) {
                push @allowed, { perl => $might_fail };
            }
        }
    }
    push @allowed, { env => 'COVERAGE=1' }
        unless list_contains_hash( \@allowed, { env => 'COVERAGE=1' } );
    $config->{matrix}{allow_failures} = \@allowed if @allowed;
}

{
    no autovivification;
    if ( exists $config->{matrix}{allow_failures}
        && !exists $config->{matrix}{fast_finish} ) {
        say 'Enable fast finish?';
        my $enable = choose( [ 'true', 'false' ] );
        use autovivification;
        $config->{matrix}{fast_finish} = $enable;
    }
}

{
    no autovivification;
    my @before_install;
    if ($is_perl) {
        my $before
            = exists $config->{before_install}
            ? $config->{before_install}
            : [];

        my @choices = (
            'Code::TidyAll::Plugin::SortLines::Naturally',
            'Code::TidyAll::Plugin::UniqueLines',
            'Perl::Tidy',
        );

        my $parts = join ' ', map { split ' ' } @$before;
        my @pre_selected = indexes { $parts =~ m{$_} } @choices;
        @before_install = choose( \@choices, { mark => \@pre_selected } );

        unless ( any { $_ =~ m{cpanm} } @{$before} ) {
            unshift @{$before}, 'cpanm --notest App::cpm';
        }

        my @to_add;
        if (@before_install) {
            my @before = @{$before};
            for my $module (@before_install) {
                if ( none { $_ =~ m{$module} } @before ) {
                    push @to_add, $module;
                }
            }

            if (@to_add) {
                push @before,
                    (
                    'AUTHOR_TESTING=0 cpm install --workers $(test-jobs) --global '
                        . join ' ', @to_add );
                $config->{before_install} = \@before;
            }
        }
    }
}

{
    no autovivification;
    my @install;
    if ($is_perl) {
        my $install
            = exists $config->{install}
            ? $config->{install}
            : [];

        my $cover
            = 'cpan-install --coverage   # installs coverage prereqs, if enabled';
        my $cpm
            = 'AUTHOR_TESTING=0 cpm install --cpanfile cpanfile --workers $(test-jobs) --global --with-recommends --with-suggests --with-configure --with-develop';

        unless ( any { $_ =~ m{cpm install} } @{ $config->{install} } ) {
            unshift @{ $config->{install} }, $cpm;
        }
        unless ( any { $_ =~ m{cover} } @{ $config->{install} } ) {
            unshift @{ $config->{install} }, $cover;
        }
    }
}

{
    no autovivification;
    if ( $is_perl && $perl_helpers ) {
        if ( exists $config->{script} && !ref( $config->{script} ) ) {
            $config->{script} = [ $config->{script} ];
        }
        if (
            !exists $config->{script}
            || (
                exists $config->{script} && none { $_ =~ m{j} }
                @{ $config->{script} }
            )
        ) {
            $config->{script} = ['prove -lr -j$(test-jobs) t'];
        }
    }
}

sub list_contains_hash {
    my $list = shift;
    my $hash = Dumper(shift);
    return any { Dumper($_) eq $hash } @{$list};
}

# maybe install App::cpm for faster installs

DumpFile( $config_file, $config );

exit(0);
