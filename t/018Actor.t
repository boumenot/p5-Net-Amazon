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

like($resp->as_string(), qr/First Dates.*?Anger Management/s, "Examine Movies");

my @starring = $properties[0]->starring();

is($properties[0]->actor, "Adam Sandler", "Check actor");
is($starring[0], "Adam Sandler", "Check starring");
is($properties[0]->director, "Peter Segal", "Check director");
like($properties[0]->title, qr/50 First Dates/, "Check title");
is($properties[0]->studio, "Sony Pictures", "Check studio");
is($properties[0]->theatrical_release_date, "2004-02-13", "Check theatrical release date");
is($properties[0]->media, "DVD", "Check media");
is($properties[0]->Media, "DVD", "Check Media");
is($properties[0]->nummedia, 1, "Check nummedia");
is($properties[0]->NumMedia, 1, "Check NumMedia");
is($properties[0]->upc, "043396014268", "Check UPC");
like($properties[0]->mpaa_rating, qr/PG\-13/, "Check MPAA rating");
is($properties[0]->region_code, 99, "Check region code");
is($properties[0]->label, "Sony Pictures", "Check label");
is($properties[0]->running_time, "99", "Check running time");
is($properties[0]->publisher, "Sony Pictures", "Check publisher");
is($properties[0]->ean, "0043396014268", "Check ean");
is($properties[0]->feature, "AC-3", "Check feature");
is(scalar($properties[0]->features), 10, "Check number of features");

