#########################
# Artist Search tests
#########################
use warnings;
use strict;

use Test::More tests => 22;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon;
use Net::Amazon::Request::Author;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "author.xml");
################################################################

my $ua = Net::Amazon->new(
    token         => 'YOUR_AMZN_TOKEN',
    #response_dump => 1,
);

my $req = Net::Amazon::Request::Author->new(
    author => "Michael Schilli",
);

   # Response is of type Net::Amazon::Artist::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 4, "4 books");

like($resp->as_string(), qr/JumpStart Guide.*?Management/s, "Examine Books");
 
is($properties[0]->author, "Michael Schilli", "Check author");
is($properties[0]->binding, "Paperback", "Check binding");
is($properties[0]->Binding, "Paperback", "Check Binding");
is($properties[0]->title, "Perl Power!: A JumpStart Guide to Programming with Perl 5", "Check title");
is($properties[0]->publisher, "Addison-Wesley Professional", "Check publisher");
is($properties[0]->isbn, "0201360683", "Check isbn");
is($properties[0]->ASIN, "0201360683", "Check ASIN");
is($properties[0]->Asin, "0201360683", "Check Asin");
is($properties[0]->edition, "Pap/Cdr", "Check edition");
is($properties[0]->ean, "9780201360684", "Check ean");
is($properties[0]->year, "1998", "Check year");
is($properties[0]->Catalog, "Book", "Check Catalog");
is($properties[0]->SmallImageUrl,  "http://ecx.images-amazon.com/images/I/01XB0VVS3VL.jpg", "Checking small image URL");
is($properties[0]->ImageUrlSmall,  "http://ecx.images-amazon.com/images/I/01XB0VVS3VL.jpg", "Checking small image URL");
is($properties[0]->MediumImageUrl, "http://ecx.images-amazon.com/images/I/215WCKSNX7L.jpg", "Checking Medium image URL");
is($properties[0]->ImageUrlMedium, "http://ecx.images-amazon.com/images/I/215WCKSNX7L.jpg", "Checking Medium image URL");
is($properties[0]->LargeImageUrl,  "http://ecx.images-amazon.com/images/I/516Y2ENTVFL.jpg", "Checking Large image URL");
is($properties[0]->ImageUrlLarge,  "http://ecx.images-amazon.com/images/I/516Y2ENTVFL.jpg", "Checking Large image URL");
