######################################################################
package Net::Amazon::Result::Seller::Listing;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon);

use Data::Dumper;
use Log::Log4perl qw(:easy);

our @DEFAULT_ATTRIBUTES = qw(
  ExchangeStartDate ExchangeConditionType
  ExchangeAsin ExchangeSellerId ExchangeEndDate ExchangePrice
  ExchangeSellerRating ExchangeStatus ExchangeId ExchangeTitle
  ExchangeQuantityAllocated ExchangeQuantity ExchangeSellerCountry
  ExchangeSellerState ExchangeSellerNickname ExchangeFeaturedCategory
  ExchangeAvailability ExchangeOfferingType ListingId ExchangeCondition
  ExchangeDescription
);

__PACKAGE__->make_accessor($_) for @DEFAULT_ATTRIBUTES;

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    if(!$options{xmlref}) {
        die "Mandatory param xmlref missing";
    }

    my $self = { 
        %options, 
               };

    bless $self, $class;

    DEBUG "Calling Listing with xmlref=", Dumper($options{xmlref});

        # Set default attributes
    for my $attr (@DEFAULT_ATTRIBUTES) {
        $self->$attr($options{xmlref}->{$attr});
    }

    return $self;
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    my $result = 
                 $self->ExchangeTitle() .
                 " (" .
                 $self->ExchangeAsin() . 
                 "): " .
                 $self->ExchangePrice() .
                 "";

    return $result;
}

1;

__END__

=head1 NAME

Net::Amazon::Result::Seller::Listing - Class for a single Listing of a Seller

=head1 SYNOPSIS

  for($seller_search_resp->result()->seller()->listings()) {
      print $_->as_string(), "\n";
  }

=head1 DESCRIPTION

C<Net::Amazon::Result::Seller::Listing> is a container for a single listing
owned by a third-party seller, who is represented by a
C<Net::Amazon::Result::Seller> object.

An object of this class is also returned by an C<Exchange> request, using
C<Net::Amazon::Response::Exchange>'s C<result> method.

=head2 METHODS

=over 4

=item ExchangeStartDate()

=item ExchangeConditionType()

=item ExchangeAsin()

=item ExchangeSellerId()

=item ExchangeEndDate()

=item ExchangePrice()

=item ExchangeSellerRating()

=item ExchangeStatus()

=item ExchangeId()

=item ExchangeTitle()

=item ExchangeQuantityAllocated()

=item ExchangeQuantity()

=item ExchangeSellerCountry()

=item ExchangeSellerState()

=item ExchangeSellerNickname()

=item ExchangeFeaturedCategory()

=item ExchangeAvailability()

=item ExchangeOfferingType()

=item ListingId()

=item ExchangeCondition()

=back

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
