use strict;
use warnings;

use DDP;
use ViaExporter qw( $foo @foo %foo );

print $foo[0];
print $foo{bar};
