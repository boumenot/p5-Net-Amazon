######################################################################
package Net::Amazon::Property::Music;
######################################################################
use base qw(Net::Amazon::Property);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = $class->SUPER::new(%options);
    bless $self, $class; # Bless into this class

    $class->SUPER::make_accessor("album");
    $class->SUPER::make_accessor("label");

    if(exists $options{xmlref}) {
        $self->init_via_xmlref($options{xmlref});
    }

    return $self;
}

##################################################
sub artist {
##################################################
    my($self, $nameref) = @_;

    # Only return the first artist
    return ($self->artists($nameref))[0];
}

##################################################
sub artists {
##################################################
    my($self, $nameref) = @_;

    if(defined $nameref) {
        if(ref $nameref eq "ARRAY") {
            $self->{artists} = $nameref;
        } else {
            $self->{artists} = [$nameref];
        }
    }

       # Return a list
    return @{$self->{artists}};
}

##################################################
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    $self->SUPER::init_via_xmlref($xmlref);

    $self->artists($xmlref->{Artists}->{Artist});
    $self->album($xmlref->{ProductName});
    $self->label($xmlref->{Manufacturer});
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    return join('/', $self->artists) . ", " .
           '"' . $self->album . '"' . ", " .
           $self->year . ", " .
           $self->OurPrice . ", " .
           $self->Asin;
}

1;

__END__

=head1 NAME

Net::Amazon::Property::Music - Class for pop CDs on amazon.com

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      for my $prop ($resp->properties) {
          print join("/", $_->artists(), " ",
                $_->album(), " ",
                $_->label(), " ",
                $_->year(), "\n";
  }

=head1 DESCRIPTION

C<Net::Amazon::Property::Music> is derived from 
C<Net::Amazon::Property> and on top of the all-purpose
methods the base class provides, it offers specialized accessors for
popular music CD parameters.

=head2 METHODS

=over 4

=item artists()

Returns a list of the CD's artists. There's also a C<artist()> method
which just returns the first artist.

=item label()

Returns the music label as a string.

=item album()

Returns the CD's title as a string.

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
