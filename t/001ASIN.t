# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More tests => 22;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon::Request::ASIN;
use Net::Amazon::Response::ASIN;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

if(! exists $ENV{NET_AMAZON_LIVE_TESTS}) {
    for(map { File::Spec->catfile($CANNED, $_) }
        qw(asin_pp.xml asin_err.xml 
           asin_mua.xml asin_cd.xml asin_cdm.xml)) {
        open FILE, "<$_" or die "Cannot open $_";
        my $data = join '', <FILE>;
        close FILE;
        push @Net::Amazon::CANNED_RESPONSES, $data;
    }
}

######################################################################
# Successful ASIN fetch
######################################################################
my $ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

my $req = Net::Amazon::Request::ASIN->new(
    asin  => '0201360683'
);

   # Response is of type Net::Amazon::ASIN::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr/Schilli/, "Found Perl Power");

######################################################################
# Error fetching ASIN
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => '123'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_error(), "Error reported correctly");
like($resp->message(), qr/Invalid/, "Invalid ASIN reported correctly");

######################################################################
# Multiple Authors
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => '0201633612'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_success(), "Found Gamma");
my($book) = $resp->properties();
like(join('&', $book->authors()), 
     qr#Erich Gamma&Richard Helm&Ralph Johnson&John Vlissides#,
     "Found multiple authors");

######################################################################
# Net::Amazon::Property::Book accessors
######################################################################
is($book->title, "Design Patterns", "Title");
is($book->year, "1995", "Year");
like($book->OurPrice, qr/\$/, "Amazon Price");
like($book->ListPrice, qr/\$/, "List Price");

######################################################################
# Successful ASIN fetch of a music CD
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => 'B00007M84Q',
    mode  => 'music',
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr/Zwan/, "Found Zwan");

######################################################################
# Net::Amazon::Property::Music accessors
######################################################################
my($cd) = $resp->properties();
is($cd->album, "Mary Star of the Sea", "Album");
is($cd->artist, "Zwan", "Artist");
is($cd->year, "2003", "Year");
like($cd->OurPrice, qr/\$/, "Amazon Price");
like($cd->ListPrice, qr/\$/, "List Price");

######################################################################
# Net::Amazon::Property::Music item with two artists
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => 'B00005A46I',
    mode  => 'music',
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr(Anne Sofie von Otter/Elvis Costello), 
     "Found Zwan");
($cd) = $resp->properties();
is($cd->artist(), "Anne Sofie von Otter", "artist() on mult artists");
is(join('#', $cd->artists()), "Anne Sofie von Otter#Elvis Costello",
    "artists() with mult artists");

