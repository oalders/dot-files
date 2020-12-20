use strict;
use warnings;

use DDP;
use ViaExporter;

my $one   = foo();
my $two   = $foo;
my @three = @foo;
my %four  = %foo;

p $one;
p $two;
p @three;
p %four;
