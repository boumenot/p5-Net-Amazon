#########################
# Test all constructors
#########################

use warnings;
use strict;

use Test::More tests => 13;
BEGIN { use_ok('Net::Amazon') };

my @request_types = (
['Artist'],
['ASIN'],
['Blended'],
['BrowseNode', 'mode'],
['Keyword', 'mode'],
['Manufacturer'],
['Power', 'mode'],
['Seller'],
['Similar'],
['TextStream'],
['UPC'],
['Wishlist'],
);

for my $t (@request_types) {
    my $class  = $t->[0];
    my $tlower = lc($t->[0]);
    my $params = join(', ', map { "$_ => '234'" }
                     ($tlower, @$t > 1 ? $t->[1] : ()));

    #print "$class $params\n";
    my $use = "use Net::Amazon::Request::$class";
    my $new = "Net::Amazon::Request::$class->new($params)";
    ok(eval "$use; $new", 
       "$new");
print $@ if $@;
}
