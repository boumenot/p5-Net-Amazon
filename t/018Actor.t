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
use Net::Amazon::Request::Actor;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "actor.xml");
################################################################

my $ua = Net::Amazon->new(
    token         => 'YOUR_AMZN_TOKEN',
    #response_dump => 1,
);

my $req = Net::Amazon::Request::Actor->new(
    actor => "Sandler",
);

   # Response is of type Net::Amazon::Artist::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 10, "10 movies");

my $i = 2;

like($resp->as_string(), qr/I Now.*?First Dates/s, "Examine Movies");

my @starring = $properties[$i]->starring();

is($properties[$i]->actor, "Adam Sandler", "Check actor");
is($starring[$i], "Jessica Biel", "Check starring");
is($properties[$i]->director, "Dennis Dugan", "Check director");
like($properties[$i]->title, qr/I Now Pronounce You Chuck/, "Check title");
is($properties[$i]->studio, "Universal Studios Home Entertainment", "Check studio");
is($properties[$i]->theatrical_release_date, "2007-07-20", "Check theatrical release date");
is($properties[$i]->media, "HD DVD", "Check media");
is($properties[$i]->Media, "HD DVD", "Check Media");
is($properties[$i]->nummedia, 1, "Check nummedia");
is($properties[$i]->NumMedia, 1, "Check NumMedia");
is($properties[$i]->upc, "025193240422", "Check UPC");
like($properties[$i]->mpaa_rating, qr/R \(Restricted\)/, "Check MPAA rating");
is($properties[$i]->region_code, 0, "Check region code");
is($properties[$i]->label, "Universal Studios Home Entertainment", "Check label");
is($properties[$i]->running_time, "116", "Check running time");
is($properties[$i]->publisher, "Universal Studios Home Entertainment", "Check publisher");
is($properties[$i]->ean, "0025193240422", "Check ean");
is($properties[$i]->feature, "Anamorphic", "Check feature");
is(scalar($properties[$i]->features), 5, "Check number of features");

