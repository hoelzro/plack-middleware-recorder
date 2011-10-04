## no critic (RequireUseStrict)
package Plack::Middleware::Recorder;

## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Plack::Middleware';

use HTTP::Request;
use IO::File;
use IO::String;
use Storable qw(nfreeze thaw);
use namespace::clean;

sub prepare_app {
    my ( $self ) = @_;

    my $output = $self->{'output'};

    $output = $self->{'output'} = IO::File->new($output, 'w') or die $!
        unless ref $output;

    $output->autoflush(1);
}

sub env_to_http_request {
    my ( $self, $env ) = @_;

    my $request = HTTP::Request->new;
    $request->method($env->{'REQUEST_METHOD'});
    $request->uri($env->{'REQUEST_URI'});
    $request->header(Content_Length => $env->{'CONTENT_LENGTH'});
    $request->header(Content_Type   => $env->{'CONTENT_TYPE'});
    foreach my $header (grep { /^HTTP_/ } keys %$env) {
        my $value = $env->{$header};
        $header   =~ s/^HTTP_//;
        $header   = uc($header);
        $header   =~ s/\b([a-z])/uc $!/ge;

        $request->header($header, $value);
    }

    my $input  = $env->{'psgi.input'};
    my $body   = IO::String->new;
    my $buffer = '';
    while($input->read($buffer, 1024) > 0) {
        print $body $buffer;
    }

    $env->{'psgi.input'} = $body;
    $request->content(${ $body->string_ref });

    return $request;
}

sub call {
    my ( $self, $env ) = @_;

    my $app    = $self->app;
    my $req    = $self->env_to_http_request($env);
    my $frozen = nfreeze($req);
    $self->{'output'}->write(pack('Na*', length($frozen), $frozen));
    $self->{'output'}->flush;

    return $app->($env);
}

1;

__END__

# ABSTRACT: Plack middleware that records your client-server interactions

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
    enable 'Recorder', output => 'requests.out';
    $app;
  };

=head1 DESCRIPTION

This middleware records the stream of requests and responses that your
application goes through to a file.  See Plack::Util::RequestProcessor
for more.

=head1 OPTIONS

=head2 output

Either a filename, a glob reference, or an IO::Handle where the serialized
requests will be written to.  To read these requests, use L<Plack::VCR>.

=head1 RATIONALE

This module was written to scratch a fairly specific itch of mine, but one I
encounter often.  I work on a lot of Javascript-heavy web applications for my
job, and I often have to fix bugs that only rear their ugly heads a dozen
clicks or so into the application.  Obviously, if the bug is in the
Javascript, there's not much I can do about it, but often the problem comes
from the output I receive from the server.  This middleware allows me to set
up debugging statements in the server and replay the requests the frontend
is submitting to get me on the right track.

=head1 FURTHER IMPROVEMENTS

The first release of this distribution is fairly simple; it only records and
retrieves requests.  In the future, I'd like a bunch of features to be added:

=head2 Specifying the output as a filename doesn't work properly with CGI (the middleware clobbers the output file)

=head2 Recording responses could be useful for generating test scripts and the like.

=head2 On that note, a script/convenience module for generating test scripts would be nice.

=head2 Currently, authorization works by just copying headers blindly.  This logic could be improved with application-specific hooks.

=head2 Request bodies are recorded directly in the output stream, and an in-memory representation is used for psgi.input.  This could be better.

=head2 Others

=head1 SEE ALSO

L<CatalystX::Test::Recorder>, L<https://github.com/miyagawa/Plack-Middleware-Test-Recorder>, L<Plack::VCR>

=cut
