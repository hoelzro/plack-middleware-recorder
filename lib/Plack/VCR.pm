## no critic (RequireUseStrict)
package Plack::VCR;

## use critic (RequireUseStrict)
use strict;
use warnings;

use Carp qw(croak);
use HTTP::Request;
use Sereal qw(decode_sereal);
use IO::File;
use Plack::VCR::Interaction;
use UNIVERSAL;

use namespace::clean;

sub new {
    my ( $class, %opts ) = @_;

    my $filename = $opts{'filename'} or croak "filename parameter required";

    my $file = IO::File->new($filename, 'r') or croak $!;

    return bless {
        file => $file,
    }, $class;
}

sub next {
    my ( $self ) = @_;

    my $file = $self->{'file'};

    my $size = '';
    my $bytes = $file->read($size, 4);
    return if $bytes == 0;
    croak "Unexpected end of file" unless $bytes == 4;

    $size = unpack('N', $size);
    if($size > -s $file) {
        croak "Invalid file contents";
    }
    my $request = '';
    $bytes = $file->read($request, $size);
    croak "Unexpected end of file" unless $bytes == $size;
    $request = decode_sereal($request);

    croak "Invalid file contents"
        unless UNIVERSAL::isa($request, 'HTTP::Request');

    return Plack::VCR::Interaction->new(
        request => $request,
    );
}

1;

# ABSTRACT: API for interacting with a frozen request file

__END__

=head1 SYNOPSIS

  use Plack::VCR;

  my $vcr = Plack::VCR->new(filename => 'requests.out');

  while(my $interaction = $vcr->next) {
    my $req = $interaction->request;
    # $req is an HTTP::Request object; do something with it
  }

=head1 DESCRIPTION

Plack::VCR provides an API for iterating over the HTTP interactions
saved to a file by L<Plack::Middleware::Recorder>.

=head1 METHODS

=head2 new(filename => $filename)

Creates a new VCR that will iterate over the interactions contained
in C<$filename>.

=head2 next

Returns the next HTTP interaction in the stream.

=head1 SEE ALSO

L<Plack::Middleware::Recorder>, L<Plack::VCR::Interaction>

=cut
