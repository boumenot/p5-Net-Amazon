######################################################################
package Net::Amazon::Request;
######################################################################

our $AMZN_XML_URL     = "http://xml.amazon.com/onca/xml2";

##################################################
sub amzn_xml_url {
##################################################
    return $AMZN_XML_URL;
}

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = {
        mode       => 'books',
        type       => 'lite',
        page       => 1,
        f          => 'xml',
        %options,
    };

    bless $self, $class;
}

##################################################
sub params {
##################################################
    my($self) = @_;

    return(%$self);
}

##################################################
# Figure out the Response class to a given Request
# class. To be used by sub classes.
##################################################
sub response_class {
##################################################
    my($self) = @_;

    my $response_class = ref($self);
    $response_class =~ s/Request/Response/;
    return $response_class;
}

1;

__END__

=head1 NAME

Net::Amazon::Request - Baseclass for requests to Amazon's web service

=head1 SYNOPSIS

    my $req = Net::Amazon::Request::XXX->new(
                     [ type => 'lite', ]
                     [ page => $start_page, ]
                     [ mode => $mode, ]
    );

=head1 DESCRIPTION

Don't use this class directly, use derived classes 
(like C<Net::Amazon::Request::ASIN>, C<Net::Amazon::Request::Wishlist>
etc.) instead to specify the type of request and its parameters.

However, there's a bunch of parameters to the constructor
that all request types have in common, here they are:

=over 4

=item type

Defaults to C<lite>, but can be set to C<heavy> if additional info
on a product is wanted.

=item mode

Defaults to C<books>, but can be set to other catalog values.

=item page

Defaults to C<1>, but can be set to a different number to 
start with a different result page. Used in conjunction with the
C<max_pages> parameter of the C<Net::Amazon> object. C<page> is the
offset, C<max_pages> is the maximum number of pages pulled in starting
at C<page>.

=back

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
