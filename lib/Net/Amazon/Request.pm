######################################################################
package Net::Amazon::Request;
######################################################################

our $AMZN_XML_URL     = "http://xml.amazon.com/onca/xml3";

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
        type       => 'heavy',
        page       => 1,
        f          => 'xml',
        sort       => '+salesrank',
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
                     [ type => 'heavy', ]
                     [ page => $start_page, ]
                     [ mode => $mode, ]
                     [ sort => $sort_type, ]
    );

=head1 DESCRIPTION

Don't use this class directly, use derived classes 
(like C<Net::Amazon::Request::ASIN>, C<Net::Amazon::Request::Wishlist>
etc.) instead to specify the type of request and its parameters.

However, there's a bunch of parameters to the constructor
that all request types have in common, here they are:

=over 4

=item type

Defaults to C<heavy>, but can be set to C<lite> if no reviews etc.
on a product are wanted.

=item mode

Defaults to C<books>, but can be set to other catalog values.

=item page

Defaults to C<1>, but can be set to a different number to 
start with a different result page. Used in conjunction with the
C<max_pages> parameter of the C<Net::Amazon> object. C<page> is the
offset, C<max_pages> is the maximum number of pages pulled in starting
at C<page>.

=item sort

Defaults to C<+salesrank>, but search results can be sorted in various
ways, depending on the type of product returned by the search.  Search
results may be sorted by the following criteria:

=over 8

=item *
Featured Items                                                           

=item *
Bestselling                                                              

=item *
Alphabetical (A-Z and Z-A)                                               

=item *
Price (High to Low and Low to High)                                      

=item *
Publication or Release Date                                              

=item *
Manufacturer                                                             

=item *
Average Customer Review                                                  

=item *
Artist Name                                   

=back

Consult L<Net::Amazon::Request::Sort> for details.

=back

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
