use strict;
use warnings;

my $filename = $ENV{PERL_SYNTAX_CHECK_FILENAME} || "";

# must return a hash that represents configuration for syntax_check
my $config = {};

__END__
=head1 CONFIGURATION EXAMPLE
  my $config = {
    # for `perl -wc` configuration
    compile => {
      skip => [
        qr/^Subroutine \S+ redefined/,
      ],
    },
    # check line by regexp
    regexp => {
      check => [
          qr/your common spelling mistake/,
      ],
    },
    # ..and freedom!
    # your custom checker which takes ($line, $filename) as arguments
    custom => {
      check => [
        sub {
          my ($line, $filename) = @_;
          if (
              $filename =~ /my_project/
              &&
              $line =~ /TODO/
          ) {
            return { type => 'WARN', message => 'TODO must be resolved' };
          }
        },
      ]
    },
  };
=cut
