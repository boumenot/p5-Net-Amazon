# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More tests => 8;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon::Request::UPC;
use Net::Amazon::Response::UPC;

#Only for debugging
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

######################################################################
# Successful UPC fetch
######################################################################
my $ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

my $req = Net::Amazon::Request::UPC->new(
    upc  => '093624843627',
    mode => 'music',
);

   # Response is of type Net::Amazon::UPC::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr#Mary Star of the Sea#, "Found Zwan");
like($resp->as_string(), qr#Zwan#, "Found Zwan");

######################################################################
# Parameters
######################################################################
my $p = ($resp->properties)[0];
is($p->artist(), "Zwan", "Artist is Zwan");
is($p->album(), "Mary Star of the Sea", "Album is Mary Star of the Sea");
is($p->year(), "2003", "Year is 2003");
is($p->label(), "Warner Brothers", "Label is Warner Brothers");
