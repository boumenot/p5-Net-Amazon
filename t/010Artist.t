#########################
# Artist Search tests
#########################
use warnings;
use strict;

use Test::More tests => 10;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon;
use Net::Amazon::Request::Artist;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "artist.xml");
################################################################

my $ua = Net::Amazon->new(
    token         => 'YOUR_AMZN_TOKEN',
    # response_dump => 1,
);

my $req = Net::Amazon::Request::Artist->new(
    artist  => "Zwan",
);

   # Response is of type Net::Amazon::Artist::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 6, "6 hits");

like($resp->as_string(), qr/Honestly.*?Honestly.*?Honestly/s, "Examine Hits");

@properties = $resp->properties();
is($properties[3]->artist, "Zwan", "Check artist");
is($properties[3]->album, "Lyric / Nobody Cept You / Autumn Leaves", 
   "Check album");
is($properties[4]->nummedia, "", "Check nummedia");
is($properties[4]->media, "Audio CD", "Check media");
is($properties[0]->label, "Warner Brothers", "Check label");
is($properties[1]->label, "Import [Generic]", "Check label");
