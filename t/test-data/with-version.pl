use strict;
use warnings;

use Cpanel::JSON::XS 4.19 qw( encode_json );
use Getopt::Long 2.40 qw();
use LWP::UserAgent 6.49;

my $foo = decode_json( { foo => 'bar' } );
my @foo = GetOptions();
