use strict;
use warnings;
use feature qw( say );

use Data::Dumper;
use Data::Printer;
use List::MoreUtils qw( first_index );
use List::Util qw ( any none uniq );
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
);

unless ( exists $config->{cache}->{directories} ) {
    $config->{cache}{directories} = ['~/perl5'];
}

if (
       $config->{language} eq 'perl'
    && exists $config->{before_install}
    && none { $_ eq 'eval $(curl https://travis-perl.github.io/init) --auto' }
    @{ $config->{before_install} }
) {
    say <<'EOF';
Enable automatic Perl helpers by adding the following to "before_install":

    eval $(curl https://travis-perl.github.io/init) --auto

EOF
}

my $perl_helpers
    = $config->{language} eq 'perl' && any { $_ =~ m{travis-perl} }
@{ $config->{before_install} };

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
        my $enable = choose(
            [ 'true', 'false' ],
        );
        my @includes
            = exists $config->{matrix}{include}{perl}
            ? @{ $config->{matrix}{include}{perl} }
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
            $config->{matrix}{include}{perl} = \@includes;
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
    $config->{matrix}{allow_failures} = \@allowed if @allowed;
}

{
    no autovivification;
    if ( exists $config->{matrix}{allow_failures}
        && !exists $config->{matrix}{fast_finish} ) {
        say 'Enable fast finish?';
        my $enable = choose(
            [ 'true', 'false' ],
        );
        use autovivification;
        $config->{matrix}{fast_finish} = $enable;
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
