#####################################################################
package Net::Amazon;
######################################################################
# Mike Schilli <m@perlmeister.com>, 2003
######################################################################

use 5.006;
use strict;
use warnings;

our $VERSION          = '0.12';
our @CANNED_RESPONSES = ();

use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use Data::Dumper;
use URI;
use Log::Log4perl qw(:easy);

use Net::Amazon::Request::ASIN;
use Net::Amazon::Request::Artist;
use Net::Amazon::Request::Keyword;
use Net::Amazon::Request::Wishlist;
use Net::Amazon::Request::UPC;
use Net::Amazon::Request::Similar;

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    if(! exists $options{token}) {
        die "Mandatory paramter 'token' not defined";
    }

    if(! exists $options{affiliate_id}) {
        $options{affiliate_id} = "webservices-20";
    }

    my $self = {
        max_pages => 5,
        %options,
               };

    help_xml_simple_choose_a_parser();

    bless $self, $class;
}

##################################################
sub search {
##################################################
    my($self, %params) = @_;

    my $req;

    if(0) {
    } elsif(exists $params{asin}) {
        $req = Net::Amazon::Request::ASIN->new(%params);
    } elsif(exists $params{artist}) {
        $req = Net::Amazon::Request::Artist->new(%params);
    } elsif(exists $params{wishlist}) {
        $req = Net::Amazon::Request::Wishlist->new(
                                   id => $params{wishlist}, %params);
    } elsif(exists $params{upc}) {
        $req = Net::Amazon::Request::UPC->new(%params);
    } elsif(exists $params{keyword}) {
        $req = Net::Amazon::Request::Keyword->new(%params);
    } elsif(exists $params{similar}) {
        $req = Net::Amazon::Request::Similar->new(asin => $params{similar},
                                                  %params);
    } else {
        warn "No Net::Amazon::Request type could be determined";
        return;
    }

    return $self->request($req);
}

##################################################
sub intl_url {
##################################################
    my($self, $url) = @_;

    # Every time Amazon is adding a new country to the web service,
    # they're rolling a dice on what the new URL is going to be.
    # This method will try to keep up with their crazy mappings.

    if(! exists $self->{locale}) {
        return $url;
    }

    if($self->{locale} eq "uk" or
       $self->{locale} eq "de") {
        $url =~ s/xml/xml-eu/;
        return $url;
    }
        
    return $url;
}

##################################################
sub request {
##################################################
    my($self, $request) = @_;

    my $AMZN_WISHLIST_BUG_ENCOUNTERED = 0;

    my $resp_class = $request->response_class();

    eval "require $resp_class;" or 
        die "Cannot find '$resp_class'";

    my $res  = $resp_class->new();

    my $url  = URI->new($self->intl_url($request->amzn_xml_url()));
    my $page = 0;
    my $ref;

    {
        $page++;

        my %params = $request->params();
        $params{page}   = $page;
        $params{locale} = $self->{locale} if exists $self->{locale};

        $url->query_form(
            'dev-t' => $self->{token},
            't'     => $self->{affiliate_id},
            %params,
        );

        my $urlstr = $url->as_string;
        my $xml = fetch_url($urlstr, $res);

        if(!defined $xml) {
            return $res;
        }

        DEBUG(sub { "Received [ " . $xml . "]" });

        my $xs = XML::Simple->new();
        $ref = $xs->XMLin($xml);

        # DEBUG(sub { Data::Dumper::Dumper($ref) });

        if(! defined $ref) {
            ERROR("Invalid XML");
            $res->message("Invalid XML");
            $res->status("");
            return $res;
        }

        if(exists $ref->{TotalPages}) {
            INFO("Page $page/$ref->{TotalPages}");
        }

        if(exists $ref->{ErrorMsg}) {

            if($AMZN_WISHLIST_BUG_ENCOUNTERED &&
               $ref->{ErrorMsg} =~ /no exact matches/) {
                DEBUG("End of buggy wishlist detected");
                last;
            }
                
            ERROR("Fetch Error: $ref->{ErrorMsg}");
            $res->message("$ref->{ErrorMsg}");
            $res->status("");
            return $res;
        }

        my $new_items = $res->xmlref_add($ref);
        DEBUG("Received valid XML ($new_items items)");

        # Stop if we've fetched max_pages already
        if($self->{max_pages} <= $page) {
            DEBUG("Fetched max_pages ($self->{max_pages}) -- stopping");
            last;
        }

        # Work around the Amazon bug not setting TotalPages properly
        # for wishlists
        if(ref($res) =~ /Wishlist/ and
           !exists $ref->{TotalPages}  and
           $new_items == 10
          ) {
            $AMZN_WISHLIST_BUG_ENCOUNTERED = 1;
            DEBUG("Trying to fetch additional wishlist page (AMZN bug)");
            redo;
        }

        if(exists $ref->{TotalPages} and
           $ref->{TotalPages} > $page) {
            DEBUG("Page $page of $ref->{TotalPages} fetched - continuing");
            redo;
        }

        # We're gonna fall out of this loop here.
    }

    $res->status(1);
    return $res;
}

##################################################
sub fetch_url {
##################################################
    my($url, $res) = @_;

    my $max_retries = 2;

    INFO("Fetching $url");

    if(@CANNED_RESPONSES) {
        INFO("Serving canned response (testing)");
        return shift @CANNED_RESPONSES;
    }

    my $ua = LWP::UserAgent->new();
    my $resp;

    {
        $resp = $ua->request(GET $url);

        if($resp->is_error) {
            $res->status("");
            $res->message($resp->message);
            return undef;
        }

        if($resp->content =~ /<ErrorMsg>/ &&
           $resp->content =~ /Please retry/i) {
            if($max_retries-- >= 0) {
                INFO("Temporary Amazon error, retrying");
                sleep(1);
                redo;
            } else {
                INFO("Out of retries, giving up");
                $res->status("");
                $res->message("Too many temporary Amazon errrors");
                return undef;
            }
        }
    }

    return $resp->content();
}

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;

            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

##################################################
sub xmlref_add {
##################################################
    my($self, $xmlref) = @_;

    my $nof_items_added = 0;

    # Push a nested hash structure, retrieved via XMLSimple, onto the
    # object's internal 'xmlref' entry, which holds a ref to an array, 
    # whichs elements are refs to hashes holding an item's attributes
    # (like OurPrice etc.)

    #DEBUG("xmlref_add ", Data::Dumper::Dumper($xmlref));

    unless(ref($self->{xmlref}) eq "HASH" &&
           ref($self->{xmlref}->{Details}) eq "ARRAY") {
        $self->{xmlref}->{Details} = [];
    }

    if(ref($xmlref->{Details}) eq "ARRAY") {
        # Is it an array of items?
        push @{$self->{xmlref}->{Details}}, @{$xmlref->{Details}};
        $nof_items_added = scalar @{$xmlref->{Details}};
    } else {
        # It is a single item
        push @{$self->{xmlref}->{Details}}, $xmlref->{Details};
        $nof_items_added = 1;
    }

    #DEBUG("xmlref_add (after):", Data::Dumper::Dumper($self));
    return $nof_items_added;
}

##################################################
sub help_xml_simple_choose_a_parser {
##################################################
    
    eval "require XML::Parser";
    unless($@) {
        $XML::Simple::PREFERRED_PARSER = "XML::Parser";
        return;
    }

    eval "require XML::SAX::PurePerl";
    unless($@) {
        $XML::Simple::PREFERRED_PARSER = "XML::SAX::PurePerl";
        return;
    }
}

1;

__END__

=head1 NAME

Net::Amazon - Framework for accessing amazon.com via SOAP and XML/HTTP

=head1 SYNOPSIS

  use Net::Amazon;

  my $ua = Net::Amazon->new(token => 'YOUR_AMZN_TOKEN');

    # Get a request object
  my $response = $ua->search(asin => '0201360683');

  if($response->is_success()) {
      print $response->as_string(), "\n";
  } else {
      print "Error: ", $response->message(), "\n";
  }

=head1 ABSTRACT

  Net::Amazon provides an object-oriented interface to amazon.com's
  SOAP and XML/HTTP interfaces. This way it's possible to create applications
  using Amazon's vast amount of data via a functional interface, without
  having to worry about the underlying communication mechanism.

=head1 DESCRIPTION

C<Net::Amazon> works very much like C<LWP>: First you define a useragent
like

  my $ua = Net::Amazon->new(
      token     => 'YOUR_AMZN_TOKEN',
      max_pages => 3,
  );

which you pass your personal amazon developer's token (can be obtained
from L<http://amazon.com/soap>) and (optionally) the maximum number of 
result pages the agent is going to request from Amazon in case all
results don't fit on a single page (typically holding 20 items).

According to the different search methods on Amazon, there's a bunch
of different request types in C<Net::Amazon>. The user agent's 
convenience method C<search()> triggers different request objects, 
depending on which parameters you pass to it:

=over 4

=item C<< $ua->search(asin => "0201360683") >>

The C<asin> parameter has Net::Amazon search for an item with the 
specified ASIN. Returns at most one result.

=item C<< $ua->search(artist => "Rolling Stones") >>

The C<artist> parameter has the user agent search for items created by
the specified artist. Can return many results.

=item C<< $ua->search(keyword => "perl xml", mode => "books") >>

Search by keyword, mandatory parameters C<keyword> and C<mode>.
Can return many results.

=item C<< $ua->search(wishlist => "1XL5DWOUFMFVJ") >>

Search for all items in a specified wishlist.
Can return many results.

=item C<< $ua->search(upc => "075596278324", mode => "music") >>

Music search by UPC (product barcode), mandatory parameter C<upc>.
C<mode> has to be set to C<music>. Returns at most one result.

=item C<< $ua->search(similar => "0201360683") >>

Search for all items similar to the one represented by the ASIN provided.
Can return many results.

=back

The user agent's C<search> method returns a response object, which can be 
checked for success or failure:

  if($resp->is_success()) {
      print $resp->as_string();
  } else {
      print "Error: ", $resp->message(), "\n";
  }

In case the request succeeds, the response contains one or more
Amazon 'properties', as it calls the products found.
All matches can be retrieved from the Response 
object using it's C<properties()> method.

Response objects always have the methods 
C<is_success()>,
C<is_error()>,
C<message()>,
C<as_string()> and
C<properties()> available.

C<properties()> returns one or more C<Net::Amazon::Property> objects of type
C<Net::Amazon::Property> (or one of its subclasses like
C<Net::Amazon::Property::Book>, C<Net::Amazon::Property::Music>
or Net::Amazon::Property::DVD), each
of which features accessors named after the attributes of the product found
in Amazon's database:

    for ($resp->properties) {
       print $_->Asin(), " ",
             $_->OurPrice(), "\n";
    }

Also the specialized classes C<Net::Amazon::Property::Book> and
C<Net::Amazon::Property::Music> feature convenience methods like
C<authors()> (returning the list of authors of a book) or 
C<album()> for CDs, returning the album title.

=head2 Requests behind the scenes

C<Net::Amazon>'s C<search()> method is just a convenient way to 
create different kinds of request objects behind the scenes and
trigger them to send requests to Amazon.

Depending on the parameters fed to the C<search> method, C<Net::Amazon> will
determine the kind of search requested and create one of the following
request objects:

=over 4

=item Net::Amazon::Request::ASIN

Search by ASIN, mandatory parameter C<asin>. 
Returns at most one result.

=item Net::Amazon::Request::Artist

Music search by Artist, mandatory parameter C<artist>.
Can return many results.

=item Net::Amazon::Request::Keyword

Keyword search, mandatory parameters C<keyword> and C<mode>.
Can return many results.

=item Net::Amazon::Request::UPC

Music search by UPC (product barcode), mandatory parameter C<upc>.
C<mode> has to be set to C<music>. Returns at most one result.

=back

Check the respective man pages for details on these request objects.
Request objects are typically created like this (with a Keyword query
as an example):

    my $req = Net::Amazon::Request::Keyword->new(
        keyword   => 'perl',
        mode      => 'books',
    );

and are handed over to the user agent like that:

    # Response is of type Net::Amazon::Response::ASIN
  my $resp = $ua->request($req);

The convenient C<search()> method just does these two steps in one.

=head2 METHODS

=over 4

=item $ua = Net::Amazon->new(token => $token, ...)

Create a new Net::Amazon useragent. C<$token> is the value of 
the mandatory Amazon developer's token, which can be obtained from
L<http://amazon.com/soap>. 

Additional optional parameters:

=over 4

=item C<< max_pages => $max_pages >>

sets how many 
result pages the module is supposed to fetch back from Amazon, which
only sends back 10 results per page. 

=item C<< affiliate_id => $affiliate_id >>

your Amazon affiliate ID, if you have one. It defaults to 
C<webservices-20> which is currently (as of 06/2003) 
required by Amazon.

=back

=item C<< $resp = $ua->request($request) >>

Sends a request to the Amazon web service. C<$request> is of a 
C<Net::Amazon::Request::*> type and C<$response> will be of the 
corresponding C<Net::Amazon::Response::*> type.

=back

=head2 Accessing foreign Amazon Catalogs

As of this writing (07/2003), Amazon also offers its web service for
the UK, Germany, and Japan. Just pass in

    locale => 'uk'
    locale => 'de'
    locale => 'jp'

respectively to C<Net::Amazon>'s constructor C<new()> and instead of returning
results sent by the US mothership, it will query the particular country's
catalog and show prices in (gack!) local currencies.

=head2 EXAMPLE

Here's a full-fledged example doing a artist search:

    use Net::Amazon;
    use Net::Amazon::Request::Artist;
    use Data::Dumper;

    die "usage: $0 artist\n(use Zwan as an example)\n"
        unless defined $ARGV[0];

    my $ua = Net::Amazon->new(
        token       => 'YOUR_AMZN_TOKEN',
    );

    my $req = Net::Amazon::Request::Artist->new(
        artist  => $ARGV[0],
    );

       # Response is of type Net::Amazon::Artist::Response
    my $resp = $ua->request($req);

    if($resp->is_success()) {
        print $resp->as_string, "\n";
    } else {
        print $resp->message(), "\n";
    }

And here's one displaying someone's wishlist:

    use Net::Amazon;
    use Net::Amazon::Request::Wishlist;

    die "usage: $0 wishlist_id\n" .
        "(use 1XL5DWOUFMFVJ as an example)\n" unless $ARGV[0];

    my $ua = Net::Amazon->new(
        token       => 'YOUR_AMZN_TOKEN',
    );

    my $req = Net::Amazon::Request::Wishlist->new(
        id  => $ARGV[0]
    );

       # Response is of type Net::Amazon::ASIN::Response
    my $resp = $ua->request($req);

    if($resp->is_success()) {
        print $resp->as_string, "\n";
    } else {
        print $resp->message(), "\n";
    }

=head1 DEBUGGING

If something's going wrong and you want more verbosity, just bump up
C<Net::Amazon>'s logging level. C<Net::Amazon> comes with C<Log::Log4perl>
statements embedded, which are disabled by default. However, if you initialize 
C<Log::Log4perl>, e.g. like

    use Net::Amazon;
    use Log::Log4perl qw(:easy);

    Log::Log4perl->easy_init($DEBUG);
    my Net::Amazon->new();
    # ...

you'll see what's going on behind the scenes, what URLs the module 
is requesting from Amazon and so forth. Log::Log4perl allows all kinds
of fancy stuff, like writing to a file or enabling verbosity in certain
parts only -- check http://log4perl.sourceforge.net for details.

=head1 LIVE TESTING

Results returned by Amazon can be incomplete or simply wrong at times,
due to their "best effort" design of the service. This is why the test
suite that comes with this module has been changed to perform its test
cases against canned data. If you want to perform the tests against
the live Amazon servers instead, just set the environment variable

    NET_AMAZON_LIVE_TESTS=1

=head1 INSTALLATION

C<Net::Amazon> depends on Log::Log4perl, which can be pulled from CPAN by
simply saying

    perl -MCPAN -eshell 'install Log::Log4perl'

Also, it needs XML::Simple 2.x, which can be obtained in a similar way.

Once all dependencies have been resolved, C<Net::Amazon> installs with
the typical sequence

    perl Makefile.PL
    make
    make test
    make install

Make sure you're connected to the Internet while running C<make test>
because it will actually contact amazon.com and run a couple of live tests.

The module's distribution tarball and documentation are available at

    http://perlmeister.com/devel/#amzn 

and on CPAN.

=head1 SEE ALSO

=head1 CONTACT

The C<Net::Amazon> project's home page is hosted on 

    http://net-amazon.sourceforge.net

where you can find documentation, news and the latest development and
stable releases for download. If you have questions about how to
use C<Net::Amazon>, want to report a bug or just participate in its
development, please send a message to the mailing 
list amazon-net-devel@lists.sourceforge.net

=head1 AUTHOR

Mike Schilli, E<lt>na@perlmeister.comE<gt> (Please contact me via the mailing list: net-amazon-devel@lists.sourceforge.net )

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>na@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
