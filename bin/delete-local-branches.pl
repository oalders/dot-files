use strict;
use warnings;
use feature qw( say );

use IO::Prompt::Tiny qw/prompt/;

my @branches = grep { $_ ne '  master' && $_ !~ m{\A\*} } split q{\n},
    `git branch`;

foreach my $branch ( @branches ) {
    my $answer = prompt( "Delete $branch Yes or no? (y/n)", "n" );
    if ( $answer eq 'y' ) {
        my $success = `git branch -D $branch`;
        say $success;
    }
    else {
        say "Skipping $branch";
    }
}
