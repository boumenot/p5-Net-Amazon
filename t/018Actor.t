#########################
# Artist Search tests
#########################
use warnings;
use strict;

use Test::More tests => 24;
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

my $i = 3;

like($resp->as_string(), qr/Bedtime Stories.*?Wedding Singer/s, "Examine Movies");

my @starring = $properties[$i]->starring();

is($properties[$i]->actor, "Adam Sandler", "Check actor");
is($starring[$i], "Allen Covert", "Check starring");
is($properties[$i]->director, "Frank Coraci", "Check director");
like($properties[$i]->title, qr/The Wedding Singer.*/, "Check title");
is($properties[$i]->studio, "New Line Home Video", "Check studio");
is($properties[$i]->ReleaseDate, "2009-04-07", "Check release date");
is($properties[$i]->theatrical_release_date, "1998", "Check theatrical release date");
is($properties[$i]->media, "Blu-ray", "Check media");
is($properties[$i]->Media, "Blu-ray", "Check Media");
is($properties[$i]->nummedia, 1, "Check nummedia");
is($properties[$i]->NumMedia, 1, "Check NumMedia");
is($properties[$i]->upc, "794043128202", "Check UPC");
like($properties[$i]->mpaa_rating, qr/Unrated/, "Check MPAA rating");
is($properties[$i]->region_code, "", "Check region code");
is($properties[$i]->label, "New Line Home Video", "Check label");
is($properties[$i]->running_time, "100", "Check running time");
is($properties[$i]->publisher, "New Line Home Video", "Check publisher");
is($properties[$i]->ean, "0794043128202", "Check ean");
is($properties[$i]->feature, "AC-3", "Check feature");
is(scalar($properties[$i]->features), 7, "Check number of features");

