# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon::Request::Wishlist;
use Net::Amazon::Response::Wishlist;

my $CANNED = "canned";
$CANNED = "t/canned" unless -d $CANNED;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level  => $DEBUG, file => "STDOUT",
#                          layout => "%F{1}%L> %m%n" });

######################################################################
# Get a canned 1-item wishlist
######################################################################
open FILE, "<$CANNED/wishlist1.xml" or die "Cannot open $CANNED/wishlist1.xml";
my $data = join '', <FILE>;
close FILE;

push @Net::Amazon::CANNED_RESPONSES, $data;

my $ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

my $req = Net::Amazon::Request::Wishlist->new(
    id  => '1XL5DWOUFMFVJ'
);

   # Response is of type Net::Amazon::ASIN::Response
my $resp = $ua->request($req);

like($resp->as_string(), qr#Richard M. Stallman/Lawrence Lessig/Joshua Gay#, "Found Stallman");

######################################################################
# Get a canned 10-item wishlist
######################################################################
for("$CANNED/wishlist10_1.xml", "$CANNED/wishlist10_2.xml") {
    open FILE, "<$_" or die "Cannot open $_";
    my $data = join '', <FILE>;
    close FILE;
    push @Net::Amazon::CANNED_RESPONSES, $data;
}

$ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

$req = Net::Amazon::Request::Wishlist->new(
    id  => '1XL5DWOUFMFVJ'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

like($resp->as_string(), qr#Samsung.*?Cornea#s, "Complete 10-item list");

######################################################################
# Get a canned 11-item wishlist
######################################################################
for("$CANNED/wishlist10_1.xml", "$CANNED/wishlist1.xml") {
    open FILE, "<$_" or die "Cannot open $_";
    my $data = join '', <FILE>;
    close FILE;
    push @Net::Amazon::CANNED_RESPONSES, $data;
}

$ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

$req = Net::Amazon::Request::Wishlist->new(
    id  => '1XL5DWOUFMFVJ'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

#print $resp->as_string;
like($resp->as_string(), qr#Samsung.*?Stallman#s, "Complete 11-item list");

######################################################################
# Successful Wishlist fetch
######################################################################
$ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

$req = Net::Amazon::Request::Wishlist->new(
    id  => '1XL5DWOUFMFVJ'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr#Richard M. Stallman/Lawrence Lessig/Joshua Gay#, "Live watchlist fetch");
