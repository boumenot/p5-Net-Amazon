#############################################
package Net::Amazon::Response::Seller;
#############################################
use base qw(Net::Amazon::Response);

use Net::Amazon::Result::Seller;
use Data::Dumper;
use Log::Log4perl qw(:easy);

##############################
sub new {
##############################
    my($class, %options) = @_;
   
    my $self = $class->SUPER::new(%options);
    bless $self, $class;   # reconsecrate
}

##################################################
sub result {
##################################################
    my($self) = @_;

    if($self->is_success()) {
        DEBUG "Calling Seller constructor with ", Dumper($self);
        return Net::Amazon::Result::Seller->new(
            xmlref => $self->{xmlref}->{SellerSearchDetails}->[0],
        );
    }

    return undef;
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    return $self->result()->as_string();
}

##################################################
sub xmlref_add {
##################################################
    my($self, $xmlref) = @_;

    my $nof_items_added = 0;

    unless(ref($self->{xmlref}) eq "HASH" &&
        ref($self->{xmlref}->{SellerSearchDetails}) eq "ARRAY") {
        $self->{xmlref}->{Details} = [];
    }

    if(ref($xmlref->{SellerSearchDetails}) eq "ARRAY") {
            # Is it an array of items?
        push @{$self->{xmlref}->{SellerSearchDetails}},
             @{$xmlref->{SellerSearchDetails}};
        $nof_items_added = scalar @{$xmlref->{SellerSearchDetails}};
    } else {
            # It is a single item
        push @{$self->{xmlref}->{SellerSearchDetails}},
             $xmlref->{SellerSearchDetails};
        $nof_items_added = 1;
    }

    #DEBUG("xmlref_add (after):", Data::Dumper::Dumper($self));
    return $nof_items_added;
} 

1;
