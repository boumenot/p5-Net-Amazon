######################################################################
package Net::Amazon::Attribute::Review;
######################################################################
use Log::Log4perl qw(:easy);
use base qw(Net::Amazon);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = {
        rating  => "",
        summary => "",
        comment => "",
        %options,
    };

    $class->make_accessor("rating");
    $class->make_accessor("summary");
    $class->make_accessor("comment");

    bless $self, $class;
}

##################################################
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    for(qw(Rating Summary Comment)) {
        my $method = lc($_);
        if($xmlref->{$_}) {
            $self->$method($xmlref->{$_});
        } else {
            #LOGWARN "No '$_'";
            return undef;
        }
    }
}

1;

__END__

=head1 NAME

Net::Amazon::Attribute::Review - Customer Review Class

=head1 SYNOPSIS

    use Net::Amazon::Attribute::Review;
    my $rev = Net::Amazon::Attribute::Review->new(
                 'rating'  => $rating,
                 'summary' => $summary,
                 'comment' => $comment,
    );

=head1 DESCRIPTION

C<Net::Amazon::Attribute::Review> holds customer reviews.

=head2 METHODS

=over 4

=item rating()

Accessor for the numeric value of the rating.

=item summary()

Accessor for the string value of the summary.

=item comment()

Accessor for the string value of the customer comment.

=back

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

__END__
      <Reviews>
         <AvgCustomerRating>4.33</AvgCustomerRating>
         <TotalCustomerReviews>6</TotalCustomerReviews>
         <CustomerReview>
            <Rating>4</Rating>
            <Summary>Good introduction to Perl, and great reference</Summary>
            <Comment>From its corny title you might expect another one of those 

