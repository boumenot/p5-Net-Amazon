#####################################################################
package Net::Amazon;
######################################################################
# Mike Schilli <m@perlmeister.com>, 2003
######################################################################

use 5.006;
use strict;
use warnings;

our $VERSION          = '0.22';
our @CANNED_RESPONSES = ();

use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use Data::Dumper;
use URI;
use Log::Log4perl qw(:easy);

use Net::Amazon::Request::ASIN;
use Net::Amazon::Request::Artist;
use Net::Amazon::Request::BrowseNode;
use Net::Amazon::Request::Keyword;
use Net::Amazon::Request::Wishlist;
use Net::Amazon::Request::UPC;
use Net::Amazon::Request::Similar;
use Net::Amazon::Request::Power;
use Net::Amazon::Request::TextStream;

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
    } elsif(exists $params{blended}) {
        $req = Net::Amazon::Request::Blended->new(%params);
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
    } elsif(exists $params{power}) {
        $req = Net::Amazon::Request::Power->new(%params);
    } elsif(exists $params{browsenode}) {
        $req = Net::Amazon::Request::BrowseNode->new(%params);
    } elsif(exists $params{manufacturer}) {
        $req = Net::Amazon::Request::Manufacturer->new(%params);
    } elsif(exists $params{textstream}) {
        $req = Net::Amazon::Request::TextStream->new(%params);

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

    if ($self->{locale} eq "jp") {
       $url =~ s/\.com/.co.jp/;
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
    my $page = $request->{page};
    my $ref;

    {
        my %params = $request->params();
        $params{page}   = $page;
        $params{locale} = $self->{locale} if exists $self->{locale};

        $url->query_form(
            'dev-t' => $self->{token},
            't'     => $self->{affiliate_id},
            %params,
        );

        my $urlstr = $url->as_string;
        my $xml = fetch_url($self, $urlstr, $res);

        if(!defined $xml) {
            return $res;
        }

        DEBUG(sub { "Received [ " . $xml . "]" });

        my $xs = XML::Simple->new();
        $ref = $xs->XMLin($xml);

        # DEBUG(sub { Data::Dumper::Dumper($ref) });

        if(! defined $ref) {
            ERROR("Invalid XML");
            $res->messages( [ "Invalid XML" ]);
            $res->status("");
            return $res;
        }

        if(exists $ref->{TotalPages}) {
            INFO("Page $page/$ref->{TotalPages}");
        }

        if(exists $ref->{TotalResults}) {
            $res->total_results( $ref->{TotalResults} );
        }

        if(exists $ref->{ErrorMsg}) {

            if($AMZN_WISHLIST_BUG_ENCOUNTERED &&
               $ref->{ErrorMsg} =~ /no exact matches/) {
                DEBUG("End of buggy wishlist detected");
                last;
            }
                
	    if (ref($ref->{ErrorMsg}) eq "ARRAY") {
	      # multiple errors, set arrary ref
	      $res->messages( $ref->{ErrorMsg} );
	    } else {
	      # single error, create array
	      $res->messages( [ $ref->{ErrorMsg} ] );
            }
            ERROR("Fetch Error: " . $res->message );
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
            $page++;
            redo;
        }

        if(exists $ref->{TotalPages} and
           $ref->{TotalPages} > $page) {
            DEBUG("Page $page of $ref->{TotalPages} fetched - continuing");
            $page++;
            redo;
        }

        # We're gonna fall out of this loop here.
    }

    $res->status(1);
    # We have a valid response, so if TotalResults isn't set, 
    # we most likely have a single response
    $res->total_results(1) unless defined $res->total_results();
    return $res;
}

##################################################
sub fetch_url {
##################################################
    my($self, $url, $res) = @_;

    my $max_retries = 2;

    INFO("Fetching $url");

    if(@CANNED_RESPONSES) {
        INFO("Serving canned response (testing)");
        return shift @CANNED_RESPONSES;
    }

    if(exists $self->{cache}) {
        my $resp = $self->{cache}->get($url);
        if(defined $resp) {
            INFO("Serving from cache");
            return $resp;
        }

        INFO("Cache miss");
    }

    my $ua = LWP::UserAgent->new();
    my $resp;

    {
        $resp = $ua->request(GET $url);

        if($resp->is_error) {
            $res->status("");
            $res->messages( [ $resp->message ] );
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
                $res->messages( [ "Too many temporary Amazon errors" ] );
                return undef;
            }
        }
    }

    if(exists $self->{cache}) {
        $self->{cache}->set($url, $resp->content());
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
# Make accessors for arrays
##################################################
sub make_array_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$nameref) = \@_;
            if(defined \$nameref) {
                if(ref \$nameref eq "ARRAY") {
                    \$self->{$name} = \$nameref;
                } else {
                    \$self->{$name} = [\$nameref];
                }
            }
               # Return a list
            if(exists \$self->{$name} and
               ref \$self->{$name} eq "ARRAY") {
                return \@{\$self->{$name}};
            }

            return undef;
        }
EOT

    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

##################################################
sub artist {
##################################################
    my($self, $nameref) = @_;

    # Only return the first artist
    return ($self->artists($nameref))[0];
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

=item C<< $ua->search(browsenode=>"4025", mode=>"books" [, keywords=>"perl"]) >>

Returns a list of items by category ID (node). For example node "4025"
is the CGI books category.  You can add a keywords parameter to filter 
the results by that keyword.

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

=item C<< $ua->search(power => "subject: perl and author: schwartz", mode => "books") >>

Initiate a power search for all books matching the power query.
Can return many results. See L<Net::Amazon::Request::Power> for details.

=item C<< $ua->search(manufacturer => "o'reilly", mode => "books") >>

Initiate a search for all items made by a given manufacturrer.
Can return many results. See L<Net::Amazon::Request::Manufacturer> 
for details.

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

In case the request fails, the response contains one or more
error messages. The response object's C<message()> method will
return it (or them) as a single string, while C<messages()> (notice
the plural) will
return a reference to an array of message strings.

Response objects always have the methods 
C<is_success()>,
C<is_error()>,
C<message()>,
C<total_results()>,
C<as_string()> and
C<properties()> available.

C<total_results()> returns the total number of results the search
yielded.
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

Commonly available accessors are 
C<OurPrice()>,
C<ImageUrlLarge()>,
C<ImageUrlMedium()>,
C<ImageUrlSmall()>,
C<ReleaseDate()>,
C<Catalog()>,
C<Asin()>,
C<url()>,
C<Manufacturer()>,
C<UsedPrice()>,
C<ListPrice()>,
C<ProductName()>,
C<Availability()>.
For details, check L<Net::Amazon::Property>.

Also, the specialized classes C<Net::Amazon::Property::Book> and
C<Net::Amazon::Property::Music> feature convenience methods like
C<authors()> (returning the list of authors of a book) or 
C<album()> for CDs, returning the album title.

Customer reviews:
Every property features a C<review_set()> method which returns a
C<Net::Amazon::Attribute::ReviewSet> object, which in turn offers
a list of C<Net::Amazon::Attribute::Review> objects. Check the respective
man pages for details on what's available.

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

=item Net::Amazon::Request::BrowseNode

Returns category (node) listing. Mandatory parameters C<browsenode>
(must be numeric) and C<mode>. Can return many results.

=item Net::Amazon::Request::Keyword

Keyword search, mandatory parameters C<keyword> and C<mode>.
Can return many results.

=item Net::Amazon::Request::UPC

Music search by UPC (product barcode), mandatory parameter C<upc>.
C<mode> has to be set to C<music>. Returns at most one result.

=item Net::Amazon::Request::Blended

'Blended' search on a keyword, resulting in matches across the board.
No 'mode' parameter is allowed. According to Amazon's developer's kit, 
this will result in up to three matches per category and can yield
a total of 45 matches.

=item Net::Amazon::Request::Power

Understands power search strings. See L<Net::Amazon::Request::Power>
for details. Mandatory parameter C<power>.

=item Net::Amazon::Request::Manufacturer

Searches for all items made by a given manufacturer. Mandatory parameter
C<manufacturer>.

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

=head1 CACHING

Responses returned by Amazon's web service can be cached locally.
C<Net::Amazon>'s C<new> method accepts a reference to a C<Cache>
object. C<Cache> (or one of its companions like C<Cache::Memory>,
C<Cache::File>, etc.) can be downloaded from CPAN, please check their
documentation for details. In fact, any other type of cache
implementation will do as well, see the requirements below.

Here's an example utilizing a file cache which causes C<Net::Amazon> to
cache responses for 30 minutes:

    use Cache::File;

    my $cache = Cache::File->new( 
        cache_root        => '/tmp/mycache',
        default_expires   => '30 min',
    );

    my $ua = Net::Amazon->new(
        token       => 'YOUR_AMZN_TOKEN',
        cache       => $cache,
    );

C<Net::Amazon> uses I<positive> caching only, errors won't be cached. 
Erroneous requests will be sent to Amazon every time. Positive cache 
entries are keyed by the full URL used internally by requests submitted 
to Amazon.

Caching isn't limited to the C<Cache> class. Any cache object which
adheres to the following interface can be used:

        # Set a cache value
    $cache->set($key, $value);

        # Return a cached value, 'undef' if it doesn't exist
    $cache->get($key);

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

=head1 WHY ISN'T THERE SUPPORT FOR METHOD XYZ?

Because nobody wrote it yet. If Net::Amazon doesn't yet support a method
advertised on Amazon's web service, you could help us out. Net::Amazon
has been designed to be expanded over time, usually it only takes a couple
of lines to support a new method, the rest is done via inheritance within
Net::Amazon.

Here's the basic plot:

=over 4

=item *

Get Net::Amazon from CVS. Use

        # (Just hit enter when prompted for a password)
    cvs -d:pserver:anonymous@cvs.net-amazon.sourceforge.net:/cvsroot/net-amazon login
    cvs -z3 -d:pserver:anonymous@cvs.net-amazon.sourceforge.net:/cvsroot/net-amazon co Net-Amazon

If this doesn't work, just use the latest distribution from 
net-amazon.sourceforge.net.

=item *

Write a new Net::Amazon::Request::XYZ package, start with this template

    ######################################
    package Net::Amazon::Request::XYZ;
    ######################################
    use base qw(Net::Amazon::Request);

    ######################################
    sub new {
    ######################################
        my($class, %options) = @_;

        if(!exists $options{XYZ_option}) {
            die "Mandatory parameter 'XYZ_option' not defined";
        }
    
        my $self = $class->SUPER::new(%options);
    
        bless $self, $class;   # reconsecrate
    }

and add documentation. Then, create a new Net::Amazon::Response::XYZ module:

    ##############################
    package Net::Amazon::Response;
    ##############################
    use base qw(Net::Amazon::Response);

    use Net::Amazon::Property;

    ##############################
    sub new {
    ##############################
        my($class, %options) = @_;
    
        my $self = $class->SUPER::new(%options);
    
        bless $self, $class;   # reconsecrate
    }

and also add documentation to it. Then, add the line

    use Net::Amazon::Request::XYZ;

to Net/Amazon.pm.

=back

And that's it! Again, don't forget the I<add documentation> part. Modules
without documentation are of no use to anybody but yourself. 

Check out the different Net::Amazon::Request::*
and Net::Amazon::Response modules in the distribution if you need to adapt
your new module to fulfil any special needs, like a different Amazon URL
or a different way to handle the as_string() method. Also, post
and problems you might encounter to the mailing list, we're gonna help you
out.

If possible, provide a test case for your extension. When finished, send 
a patch to the mailing list at 

   net-amazon-devel@lists.sourceforge.net

and if it works, I'll accept it and will work it into the main distribution.
Your name will show up in the contributor's list below (unless you tell
me otherwise).

=head2 SAMPLE SCRIPTS

There's a number of useful scripts in the distribution's eg/ directory.
Take C<power> for example, written by Martin Streicher 
E<lt>martin.streicher@apress.comE<gt>: I lets you perform 
a I<power search> using Amazon's query language. To search for all books 
written by Randal Schwartz about Perl, call this from the command line:

    power 'author: schwartz subject: perl'

Note that you need to quote the query string to pass it as one argument
to C<power>. If a power search returns more results than you want to
process at a time, just limit the number of pages, telling C<power>
which page to start at (C<-s>) and which one to finish with (C<-f>).
Here's a search for all books on the subject C<computer>, limited
to the first 10 pages:

    power -s 1 -f 10 'subject: computer'

Check out the script C<power> in eg/ for more options.

=head2 HOW TO SEND ME PATCHES

If you want me to include your modification or enhancement 
in the distribution of Net::Amazon, please do the following:

=over 4

=item *

Work off the latest CVS version. Here's the steps to get it:

    CVSROOT=:pserver:anonymous@cvs.net-amazon.sourceforge.net:/cvsroot/net-amazon
    export CVSROOT
    cvs login (just hit Enter)
    cvs co Net-Amazon

This will create a new C<Net-Amazon> directory with the latest 
development version of C<Net::Amazon> on your local machine.

=item *

Apply your changes to this development tree.

=item *

Run a diff between the tree and your changes it in this way:

    cd Net-Amazon
    cvs diff -Nau >patch_to_mike.txt

=item *

Email me C<patch_to_mike.txt>. If your patch works (and you've included
test cases and documentation), I'll apply it on the spot.

=back

=head1 INSTALLATION

C<Net::Amazon> depends on Log::Log4perl, which can be pulled from CPAN by
simply saying

    perl -MCPAN -eshell 'install Log::Log4perl'

Also, it needs LWP::UserAgent and XML::Simple 2.x, which can be obtained 
in a similar way.

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

The following modules play well within the C<Net::Amazon> framework:

=over 4

=item C<Net::Amazon::RemoteCart>

by David Emery E<lt>dave@skiddlydee.comE<gt> provides a complete API for
creating Amazon shopping carts on a local site, managing them and finally 
submitting them to Amazon for checkout. It is available on CPAN.

=back

=head1 CONTACT

The C<Net::Amazon> project's home page is hosted on 

    http://net-amazon.sourceforge.net

where you can find documentation, news and the latest development and
stable releases for download. If you have questions about how to
use C<Net::Amazon>, want to report a bug or just participate in its
development, please send a message to the mailing 
list net-amazon-devel@lists.sourceforge.net

=head1 AUTHOR

Mike Schilli, E<lt>na@perlmeister.comE<gt> (Please contact me via the mailing list: net-amazon-devel@lists.sourceforge.net )

Contributors (thanks y'all!):

    Barnaby Claydon <bclaydon@perseus.com>
    Batara Kesuma <bkesuma@gaijinweb.com>
    Bill Fitzpatrick
    Brian Hirt <bhirt@mobygames.com>
    Dan Sully <daniel@electricrain.com>
    Jackie Hamilton <kira@cgi101.com>
    Konstantin Gredeskoul <kig@get.topica.com>
    Martha Greenberg <marthag@mit.edu>
    Martin Streicher <martin.streicher@apress.com>
    Mike Evron <evronm@dtcinc.net>
    Padraic Renaghan <padraic@renaghan.com>
    rayg <rayg@varchars.com>
    Robert Graff <rgraff@workingdemo.com>
    Tatsuhiko Miyagawa <miyagawa@livedoor.jp>
    Tony Bowden <tony@kasei.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, 2004 by Mike Schilli E<lt>na@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
