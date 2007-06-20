######################################################################
package Net::Amazon::Response::Wishlist;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Response);

use Net::Amazon::Property;
use Data::Dumper;
use Log::Log4perl qw(:easy get_logger);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

##################################################
sub xmlref_add {
##################################################
    my($self, $xmlref) = @_;

    my $nof_items_added = 0;

    unless(ref($self->{xmlref}) eq "HASH" &&
            ref($self->{xmlref}->{Items}) eq "ARRAY") {
        $self->{xmlref}->{Items} = [];
    }

    if(ref($xmlref->{Lists}->{List}->{ListItem}) eq "ARRAY") {
        push @{$self->{xmlref}->{Items}}, 
             $_->{Item} for @{$xmlref->{Lists}->{List}->{ListItem}};
        $nof_items_added = scalar @{$xmlref->{Lists}->{List}->{ListItem}};
    } else {
        push @{$self->{xmlref}->{Items}}, 
             $xmlref->{Lists}->{List}->{ListItem}->{Item};
        $nof_items_added = 1;
    }

    DEBUG("xmlref_add (after):", Data::Dumper::Dumper($self));
    return $nof_items_added;
}

##################################################
sub current_page {
##################################################
    # This is a, "I cannot determine because Amazon won't tell me."
}

##################################################
sub set_total_results {
##################################################
    # This is a, "I cannot determine because Amazon won't tell me."
}

##################################################
sub is_page_available {
##################################################
    my($self, $ref, $new_items, $page) = @_;
    DEBUG("Trying to fetch additional wishlist page (AMZN bug)");
    return ($Net::Amazon::IS_CANNED) ? $new_items == 10 : $new_items > 0;
}

##################################################
sub is_page_error {
##################################################
    my($self, $ref, $res) = @_;

    if(exists $ref->{Lists}->{Request}->{Errors}) {
        my $errref = $ref->{Lists}->{Request}->{Errors};

        if (ref($errref->{Error}) eq "ARRAY") {
            my @errors;
            for my $e (@{$errref->{Error}}) {
                return -1 if $e =~ /Valid values must be/;
                push @errors, $e->{Message};
            }
            # multiple errors, set arrary ref
            $res->messages( @errors );
        } else {
            # single error, create array
            return -1 if $errref->{Error}->{Message} =~ /Valid values must be/;
            $res->messages( [ $errref->{Error}->{Message} ] );
        }

        ERROR("Fetch Error: " . $res->message );
        $res->status("");
        return 0;
    }

    return 1;
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    return $self->SUPER::list_as_string($self->properties);
}

1;
