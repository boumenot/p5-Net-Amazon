######################################################################
package Net::Amazon::Response::Blended;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Response);

use Net::Amazon::Property;
use XML::Simple;

our @FORCE_ARRAY_FIELDS = qw(ProductLine);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    return $self->SUPER::list_as_string($self->properties);
}

##################################################
sub xmlref_add {
##################################################
    my($self, $xmlref) = @_;

    my $nof_items_added = 0;

    unless(ref($self->{xmlref}) eq "HASH" &&
           ref($self->{xmlref}->{Details}) eq "ARRAY") {
        $self->{xmlref}->{Details} = [];
    }

    if ($xmlref->{ProductLine} && (ref($xmlref->{ProductLine}) eq "ARRAY")) {
        my @lines = @{$xmlref->{ProductLine}}; # Copy the lines
            # sort the copies by relevance
        @lines = sort { $a->{RelevanceRank} <=> $b->{RelevanceRank} } @lines;

        foreach (@lines) {
              next unless $_->{ProductInfo}->{Details};
              my $details = $_->{ProductInfo}->{Details};
              if (ref($details) eq "ARRAY") {
                  push @{$self->{xmlref}->{Details}}, @$details;
                  $nof_items_added += scalar @$details;
              } else {
                  push @{$self->{xmlref}->{Details}}, $details;
                  $nof_items_added++;
              }
        }
    }

    return $nof_items_added;
}

##################################################
sub xml_parse {
##################################################
    my($self, $xml) = @_;

    my $xs = XML::Simple->new();
    return $xs->XMLin($xml, ForceArray => [ @FORCE_ARRAY_FIELDS ]);
}

1;
