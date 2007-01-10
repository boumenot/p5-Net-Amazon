######################################################################
package Net::Amazon::Request::Wishlist;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    # For backwards compatibility:
    $class->_convert_option(\%options, 'id', 'wishlist');

    $class->_assert_options_defined(\%options, 'wishlist');

    $class->_convert_option(\%options,
                            'wishlist',
                            'ListId');

	$options{'ListType'} = 'WishList';

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Wishlist - request class for wishlist search

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Wishlist;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Wishlist->new( 
      wishlist => '1XL5DWOUFMFVJ',
  );

    # Response is of type Net::Amazon::Response::Wishlist
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Wishlist> is a class used to request
a specified wishlist.

The wishlist ID (can be found as parameters in URLs when a customer's
Amazon wishlist is being pulled up) is specified in the C<id> parameter.

Upon success, the response's C<properties()> method will return a list
of C<Net::Amazon::Property::*> objects.

=head2 METHODS

=over 4

=item new(wishlist => $id)

Constructs a new C<Net::Amazon::Request::Wishlist> object, used to query
the Amazon web service for a specific wishlist, identified by the wishlist
ID.

=back

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
