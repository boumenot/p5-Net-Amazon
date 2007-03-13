#########################
# Artist Search tests
#########################
use warnings;
use strict;

use Test::More tests => 23;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon;
use Net::Amazon::Request::Director;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "director.xml");
################################################################

my $ua = Net::Amazon->new(
    token         => 'YOUR_AMZN_TOKEN',
    #response_dump => 1,
);

my $req = Net::Amazon::Request::Director->new(
    director => "miyazaki",
);

   # Response is of type Net::Amazon::Artist::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 10, "10 movies");

like($resp->as_string(), qr/Howl's Moving Castle.*?Spirited Away/s, "Examine Movies");

my @starring = $properties[0]->starring();

is($properties[0]->actor, "Chieko Baisho", "Check actor");
is($starring[0], "Chieko Baisho", "Check starring");
is($properties[0]->director, "Hayao Miyazaki", "Check director");
like($properties[0]->title, qr/Howl's Moving Castle/, "Check title");
is($properties[0]->studio, "Walt Disney Home Entertainment", "Check studio");
is($properties[0]->theatrical_release_date, "2004", "Check theatrical release date");
is($properties[0]->media, "DVD", "Check media");
is($properties[0]->Media, "DVD", "Check Media");
is($properties[0]->nummedia, 2, "Check nummedia");
is($properties[0]->NumMedia, 2, "Check NumMedia");
is($properties[0]->upc, "786936296662", "Check UPC");
like($properties[0]->mpaa_rating, qr/PG/, "Check MPAA rating");
is($properties[0]->region_code, 1, "Check region code");
is($properties[0]->label, "Walt Disney Home Entertainment", "Check label");
is($properties[0]->running_time, "119", "Check running time");
is($properties[0]->publisher, "Walt Disney Home Entertainment", "Check publisher");
is($properties[0]->ean, "0786936296662", "Check ean");
is($properties[0]->feature, "Animated", "Check feature");
is(scalar($properties[0]->features), 6, "Check number of features");

