######################################################################
package Net::Amazon::Request::Exchange;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

   if(exists $options{exchange}) {
       $options{ExchangeSearch} = $options{exchange};
       delete $options{exchange};
       $options{type} = "lite";
       $options{mode} = "";
  } else {
      die "Mandatory parameter 'exchange' not defined";
  }

#    if(!exists $options{exchange}) {
#        die "Mandatory parameter 'exchange' not defined";
#    }

   my $self = $class->SUPER::new(%options);

   bless $self, $class;   # reconsecrate
}

1;
