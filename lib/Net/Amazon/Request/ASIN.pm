######################################################################
package Net::Amazon::Request::ASIN;
######################################################################
use base qw(Net::Amazon::Request);

# These values are defined in the AWS SDK
# (http://amazon.com/webservices) under
# "Product and Catalog Data" / "ASIN and ISBN Searches"
use constant MAX_ASINS_PER_TYPE => {
    heavy => 10,
    lite  => 30,
};

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_process_asin_option(\%options);

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

##
## PRIVATE METHODS
##

# $class->_process_asin_option( OPTIONS )
#
# Takes a reference to a hash of OPTIONS ('asin' is the
# only mandatory key) and turns the 'asin' key into
# 'AsinSearch'. If the value associated with 'asin' is an array,
# we check to make sure that we're not asking for too many asins
# at once.
#
# Returns void if all goes well. If any problems are encountered,
# die() will be called.
#
sub _process_asin_option {
    my ($class, $options) = @_;

    # Only testing for existence of the 'asin' key will not catch
    # cases where someone provides an empty asin list, so we test
    # for truth instead, which is slightly better.
    die "Mandatory parameter 'asin' not provided."
        unless ( $options->{'asin'} );

    # If the asins are supplied in the form of an array, we have to
    # make sure that the caller isn't trying to ask for too many at a
    # time. If we don't make this test, those excessive asins will be
    # silently ignored by the AWS servers...resulting in potentially
    # confusing results for the user.
    if ( ref $options->{'asin'} eq 'ARRAY' ) {
        my $type      = $options{'type'} || $class->SUPER::DEFAULT_TYPE;
        my $max_asins = MAX_ASINS_PER_TYPE->{$type};

        # Dying is the right thing to do here because this is
        # indicative of a programming error.
        die "Only $max_asins may be requested at a time using type '$type'"
            if ( @{$options->{'asin'}} > $max_asins );

        $options{'asin'} = join ',', @{$options->{'asin'}};
    } elsif ( ref $options->{'asin'} ) {
        die "The 'asin' parameter must either be a scalar or an array";
    }

    $options{'AsinSearch'} = $options{'asin'};
    delete $options{'asin'};

    return;
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
single C<Net::Amazon::Property::*> object.

=head2 METHODS

=over 4

=item new( asin => $asin )

Constructs a new C<Net::Amazon::Request::ASIN> object, used to query
the Amazon web service for an item with the specified ASIN number.

C<$asin> can also be a reference to an array of ASINs, like in

    $ua->search(asin => ["0201360683", "0596005083"]) 

in which case a search for multiple ASINs is performed, returning a list of 
results.

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
