######################################################################
package Net::Amazon::Property::DVD;
######################################################################
use base qw(Net::Amazon::Property);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = $class->SUPER::new(%options);
    bless $self, $class; # Bless into this class

    $class->SUPER::make_accessor("title");
    $class->SUPER::make_accessor("studio");

    if(exists $options{xmlref}) {
        $self->init_via_xmlref($options{xmlref});
    }

    return $self;
}

##################################################
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    $self->title($xmlref->{ProductName});
    $self->studio($xmlref->{Manufacturer});
}

1;

__END__

=head1 NAME

Net::Amazon::Property::DVD - Class for DVDs on amazon.com

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      for my $prop ($resp->properties) {
          print $_->title(), " ",
                $_->studio(), " ",
                $_->year(), "\n";
  }

=head1 DESCRIPTION

C<Net::Amazon::Property::DVD> is derived from 
C<Net::Amazon::Property> and on top of the all-purpose
methods the base class provides, it offers specialized accessors for
DVD parameters.

=head2 METHODS

=over 4

=item title()

Returns the title of the DVD.

=item studio()

Returns the studio.

=item new(xmlref => $xmlref)

Initializes an object by passing a hash of hashes structure containing
the XML data returned from the service. Usually, this is just used by
C<Net::Amazon> internally to initialize objects for on backcoming
data.

=back

Check out L<Net::Amazon::Property> for all-purpose accessors, like
C<year>, C<OurPrice>, C<ListPrice>, etc.

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
