
###########################################
# Tests for Exchange requests
# Mike Schilli, 2004 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Test::More tests => 25;
use Net::Amazon;
use Net::Amazon::Result::Seller::Listing;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "exchange.xml");
################################################################

my $ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
    #response_dump => 1,
);

# Get a request object
my $resp = $ua->search(exchange => 'Y04Y3424291Y2398445');

ok($resp->is_success(), "Successful response");
ok(defined $resp->result(), "Defined seller result");

like($resp->result()->as_string(), qr/^Bold Visions.*\(1555913164\)/,
   "Exchange result as string");

my $listing = $resp->result();

is($listing->ExchangeStartDate(), "02/19/2005 04:32:20 PST", 
   "Listing Exchange Start Date");

is($listing->ExchangeAsin(), "1555913164", 
   "Listing Exchange ASIN");

is($listing->ExchangeConditionType(), "verygood", 
   "Listing ExchangeConditionType");

is($listing->ExchangeAsin(), "1555913164", 
   "Listing ExchangeAsin");

is($listing->ExchangeSellerId(), "AZPQKLIWQKVZ", 
    "Listing ExchangeSellerId");

is($listing->ExchangeEndDate(), "02/04/2008 04:32:20 PST", 
    "Listing ExchangeEndDate");

is($listing->ExchangePrice(), '$11.95', 
    "Listing ExchangePrice");

is($listing->ExchangeSellerRating(), "4.7", 
    "Listing ExchangeSellerRating");

is($listing->ExchangeStatus(), "Open", 
    "Listing ExchangeStatus");

is($listing->ExchangeId(), "Y04Y3424291Y2398445", 
    "Listing ExchangeId");

is($listing->ExchangeTitle(), "Bold Visions for the Garden: " .
    "Basics, Magic & Inspiration [Paperback]  by...", 
    "Listing ExchangeTitle");

is($listing->ExchangeQuantityAllocated(), "0", 
    "Listing ExchangeQuantityAllocated");

is($listing->ExchangeQuantity(), "1", 
    "Listing ExchangeQuantity");

is($listing->ExchangeSellerCountry(), "", 
    "Listing ExchangeSellerCountry");

is($listing->ExchangeSellerState(), "", 
    "Listing ExchangeSellerState");

is($listing->ExchangeSellerNickname(), "powells_books", 
    "Listing ExchangeSellerNickname");

is($listing->ExchangeFeaturedCategory(), "68297", 
    "Listing ExchangeFeaturedCategory");

is($listing->ExchangeAvailability(), "Usually ships in 1-2 business days",
    "Listing ExchangeAvailability");

is($listing->ExchangeOfferingType(), "used", 
    "Listing ExchangeOfferingType");

is($listing->ListingId(), "0219T568068", 
    "Listing ListingId");

is($listing->ExchangeCondition(), "", 
    "Listing ExchangeCondition");

is($listing->ExchangeDescription(), "Title: Bold Visions for the Garden: Basics, Magic & Inspiration\n: Hartlage, Richard W.\n", "Listing ExchangeDescription");

