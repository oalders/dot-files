use strict;
use warnings;
use feature qw( say );

use IO::Prompt::Tiny qw/prompt/;

my @branches = split q{\n}, `git branch | grep -v master | grep -v \\*`;

foreach my $branch ( @branches ) {
    my $answer = prompt( "Delete $branch? (y/n)", "n" );
    if ( $answer eq 'y' ) {
        my $result = `git branch -D $branch`;
        say $result;
    }
    else {
        say "Skipping $branch";
    }
}
