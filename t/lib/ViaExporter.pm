package ViaExporter;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(foo $foo @foo %foo);

sub foo { return 'from sub foo' }
our $foo = 1;
our @foo = ( 1 .. 10 );
our %foo = ( foo => 'bar' );

1;
