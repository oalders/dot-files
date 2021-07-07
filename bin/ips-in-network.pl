#!/usr/bin/env perl

# Mostly pilfered from Net::Works synopsis
#
# Usage: perl bin/ips-in-network.pl 2001:db8::/64 | more

use strict;
use warnings;
use 5.010;

use Net::Works::Network;

my $arg = shift @ARGV || die 'no network supplied';

my $network = Net::Works::Network->new_from_string( string => $arg );
say 'as string:       ' . $network->as_string();           # 192.0.2.0/24
say 'prefix length:   ' . $network->prefix_length();       # 24
say 'bits:            ' . $network->bits();                # 32
say 'network version: ' . $network->version();             # 4
say 'first address:   ' . $network->first->as_string();    # 192.0.2.0
say 'last address:    ' . $network->last->as_string();     # 192.0.2.255

my $iterator = $network->iterator();
while ( my $ip = $iterator->() ) { say $ip }
