######################################################################
package Net::Amazon::Request;
######################################################################

use warnings;
use strict;

use constant DEFAULT_MODE          => 'books';
use constant DEFAULT_TYPE          => 'heavy';
use constant DEFAULT_PAGE_COUNT    => 1;
use constant DEFAULT_FORMAT        => 'xml';
use constant DEFAULT_SORT_CRITERIA => '+salesrank';

use constant VALID_TYPES => { map { $_ => 1 } qw(heavy lite) };

our $AMZN_XML_URL  = "http://xml.amazon.com/onca/xml3";

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
        mode       => DEFAULT_MODE,
        type       => DEFAULT_TYPE,
        page       => DEFAULT_PAGE_COUNT,
        f          => DEFAULT_FORMAT,
        sort       => DEFAULT_SORT_CRITERIA,
        %options,
    };

    die "Unknown type in ", __PACKAGE__, " constructor: ",
        $self->{type} unless exists VALID_TYPES->{$self->{type}};

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

##
## 'PRIVATE' METHODS
##

# CLASS->_convert_option( OPTIONS, ORIGINAL, TARGET [, CALLBACK] )
#
# Takes a reference to a hash of OPTIONS and renames the
# ORIGINAL key name to the TARGET key name. If the optional
# CALLBACK subroutine reference is defined, that subroutine
# is invoked with two arguments:
#
#     CALLBACK->( OPTIONS, TARGET )
#
# The result of the CALLBACK's execution is then returned to
# the caller. No assumptions are made about what the CALLBACK
# should return (or even *if* is should return)--that's the
# caller's responsibility.
#
# Returns 1 in the absensence of a CALLBACK.
#
sub _convert_option {
    my ($class, $options, $original, $target, $callback) = @_;

    $options->{$target} = $options->{$original};
    delete $options->{$original};
 
    if ( exists $options->{$original} ) {
        $options->{$target} = $options->{$original};
        delete $options->{$original};
    }

    return 1 unless ( $callback );

    # The key name is explicitly passed-in so that the caller doesn't
    # have think "Hrmm..  now which key am I working on, the original
    # or the target key?" Confusion is bad.
    return $callback->($options, $target);
}

# CLASS->_assert_options_defined( OPTIONS, KEYS )
#
# Takes a reference to a hash of OPTIONS and a list of
# one or more KEYS. Tests to see if each key in KEYS
# has a defined value. Calls die() upon the first
# missing key. Otherwise, returns undef.
#
sub _assert_options_defined {
    my ($class, $options, @keys) = @_;
    
    foreach my $key ( @keys ) {
        die "Mandatory parameter '$key' not defined"
            unless ( defined $options->{$key} );
    }
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
