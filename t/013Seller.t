
###########################################
# Keyword search tests
# Mike Schilli, 2004 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Test::More tests => 7;
use Net::Amazon;
use Net::Amazon::Request::Seller;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "seller.xml");
################################################################

my $ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
    #response_dump => 1,
);

my $req = Net::Amazon::Request::Seller->new(
    seller  => 'A2GXAGU54VOP7',
);

my $resp = $ua->request(
    $req,
);

ok($resp->is_success(), "Successful response");
ok(defined $resp->result(), "Defined seller result");
is($resp->result()->as_string(), "myAthenaeum (_athenaeum_): 32000",
   "Seller result");
is($resp->result()->StoreId(), "S1CTCSZADC15MI", "StoreId accessor");
is($resp->result()->as_string(), "myAthenaeum (_athenaeum_): 32000", 
   "Seller as_string()");

# listings
my @listings = $resp->result()->listings();

is($listings[0]->ExchangeStartDate(), "05/29/2004 12:58:17 PDT", 
   "Listing 1 Start Date");
is($listings[1]->ExchangeStartDate(), "07/09/2004 23:38:08 PDT", 
   "Listing 2 Start Date");

