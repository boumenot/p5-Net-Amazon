#!/usr/bin/perl
###########################################
use warnings;
use strict;

use Net::Amazon;
use Net::Amazon::Request::Blended;

my $ua = Net::Amazon->new(token => 'AMAZON_TOKEN');
my $response = $ua->search(blended => ($ARGV[0] || "Perl"));
my @properties = $response->properties();

foreach (@properties) {
        print $_->as_string() . "\n";
}
