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

# ABSTRACT:  A short description of Plack::Middleware::Recorder

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

=head1 FUNCTIONS

=head1 SEE ALSO

=cut
