######################################################################
package Net::Amazon::Request::ASIN;
######################################################################
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    if(exists $options{asin}) {
        $options{AsinSearch} = $options{asin};
        delete $options{asin};
    } else {
        die "Mandatory parameter 'asin' not defined";
    }

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::ASIN - Class for submitting ASIN requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::ASIN;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::ASIN->new( 
      asin  => '0201360683'
  );

    # Response is of type Net::Amazon::Response::ASIN
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::ASIN> is a class used to submit ASIN requests
to the Amazon web service.

The ASIN of the item to look is specified in the C<asin> parameter.

Upon success, the responses' C<properties()> method will return one
single C<Net::Amazon::Properties::*> object.

=head2 METHODS

=over 4

=item new( asin => $asin )

Constructs a new C<Net::Amazon::Request::ASIN> object, used to query
the Amazon web service for an item with the specified ASIN number.

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
