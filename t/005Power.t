# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('Net::Amazon') };

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level => $DEBUG, file => ">out"});

use Net::Amazon;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

if(! exists $ENV{NET_AMAZON_LIVE_TESTS}) {
    for(map { File::Spec->catfile($CANNED, $_) }
        qw(power.xml power_sorted.xml power_empty.xml)) {
        open FILE, "<$_" or die "Cannot open $_";
        my $data = join '', <FILE>;
        close FILE;
        push @Net::Amazon::CANNED_RESPONSES, $data;
    }
}

######################################################################
# Successful Power search
######################################################################
my $ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

my $resp = $ua->search(
    power => "author: randal schwartz and author: tom phoenix",
    mode  => "books",
);

ok($resp->is_success(), "Successful Power fetch");
like($resp->as_string(), qr/0596004788/, "Found 1");
like($resp->as_string(), qr/0596001320/, "Found 2");
is($resp->total_results(), 2, "Found 2 total results");

######################################################################
# Power search with different sorting method
######################################################################
$ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

$resp = $ua->search(
    power => "author: randal schwartz and author: tom phoenix",
    mode  => "books",
    sort  => "+pricerank",
);

ok($resp->is_success(), "Successful sorted power fetch");
my @prices = ($resp->as_string =~ /\$([\d\.]+)/g);
my @sorted_prices = sort { $a <=> $b } @prices;
is("@prices", "@sorted_prices", "Sorted by Price");

######################################################################
# Power search with empty result
######################################################################
$ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

$resp = $ua->search(
    power => "author: randal schwartz and author: mike schilli",
    mode  => "books",
);

ok(!$resp->is_success(), "Power fetch came back empty");
