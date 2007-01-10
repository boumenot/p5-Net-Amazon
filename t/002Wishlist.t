# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon::Request::Wishlist;
use Net::Amazon::Response::Wishlist;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level  => $DEBUG, file => "STDOUT",
#                         layout => "%F{1} %L> %m%n" });

######################################################################
# Get a 1-item wishlist
######################################################################
canned("wishlist1.xml");

my $ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

my $req = Net::Amazon::Request::Wishlist->new(
    id  => '1XL5DWOUFMFVJ'
);

   # Response is of type Net::Amazon::ASIN::Response
my $resp = $ua->request($req);
like($resp->as_string(), qr#Stallman#, "Found Stallman");

######################################################################
# Get a canned 10-item wishlist
######################################################################
canned("wishlist10_1.xml");
canned("wishlist10_2.xml");

$ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

$req = Net::Amazon::Request::Wishlist->new(
    id  => '1XL5DWOUFMFVJ'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

#like($resp->as_string(), qr#Samsung.*?Cornea#s, "Complete 10-item list");
like($resp->as_string(), qr#Barry.*?Ullman#s, "Complete 10-item list");

######################################################################
# Get a canned 11-item wishlist
######################################################################
canned("wishlist10_1.xml");
canned("wishlist1.xml");

$ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

$req = Net::Amazon::Request::Wishlist->new(
    id  => '1XL5DWOUFMFVJ'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

like($resp->as_string(), qr#Barry.*?Stallman#s, "Complete 11-item list");

$req = Net::Amazon::Request::Wishlist->new(
    wishlist  => '1XL5DWOUFMFVJ'
);

ok($req, "Check 0.29 param bugfix");

######################################################################
# handle canned responses
######################################################################
sub canned {
    my($file) = @_;

    if(! exists $ENV{NET_AMAZON_LIVE_TESTS} ) {
        $file = File::Spec->catfile($CANNED, $file);
        open FILE, "<$file" or die "Cannot open $file";
        my $data = join '', <FILE>;
        close FILE;
        push @Net::Amazon::CANNED_RESPONSES, $data;
    }
}

