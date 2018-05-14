use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use List::MoreUtils qw( first_index );
use List::Util qw ( any none uniq );
use Term::Choose qw( choose );
use YAML::Tiny qw( DumpFile LoadFile );

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

if ( $config->{perl} ) {
    my %perls = map { $_ => 1 } @{ $config->{perl} };
    for my $version (@perl_versions) {
        $perls{$version} = 1;
    }
    $config->{perl} = [ sort keys %perls ];

    for my $might_fail ( 'blead', 'dev' ) {
        if ( exists $perls{$might_fail} ) {
            my $allowed
                = $config->{matrix}{include}{allow_failures} || [];
            if ( none { $_ eq $might_fail } @{$allowed} ) {
                push @{$allowed}, $might_fail;
            }
            $config->{matrix}{include}{allow_failures} = $allowed;
        }
    }
}

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
    = $config->{language} eq 'perl' && any { $_ =~ m{travis-perl-helpers} }
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
        = sort { $a cmp $b } uniq( 'aspell', 'elasticsearch', @{$apt_pkgs} );
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

{
    no autovivification;
    if ( exists $config->{matrix}{include}{allow_failures}
        && !exists $config->{matrix}{fast_finish} ) {
        say 'Enable fast finish?';
        my $enable = choose(
            [ 'true', 'false' ],
        );
        use autovivification;
        $config->{matrix}{fast_finish} = $enable;
    }
}

{
    no autovivification;
    if ( $perl_helpers ) {
        say 'Enable coverage reports?';
        my $enable = choose(
            [ 'true', 'false' ],
        );
        use autovivification;
        #$config->{matrix}{fast_finish} = $enable;
        if ( $enable eq 'true' ) {
            # get highest Perl release version
            for my $version ( reverse @perl_versions ) {
                if ( any { $_ eq $version } @{$config->{perl}} ) {
                    $config->{matrix}->{include}->{perl}
                }
            }
        }
    }
}

# enable test coverage

# maybe install App::cpm for faster installs

DumpFile( $config_file, $config );
