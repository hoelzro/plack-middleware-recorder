package Plack::VCR;

use strict;
use warnings;

use Carp qw(croak);
use Storable qw(thaw);
use IO::File;
use Plack::VCR::Interaction;

use namespace::clean;

sub new {
    my ( $class, %opts ) = @_;

    my $filename = $opts{'filename'} or croak "filename parameter required";

    my $file = IO::File->new($filename, 'r');

    return bless {
        file => $file,
    }, $class;
}

sub next {
    my ( $self ) = @_;

    my $file = $self->{'file'};

    my $size = '';
    my $bytes = $file->read($size, 4);
    return unless $bytes == 4;

    $size = unpack('N', $size);
    my $request = '';
    $bytes = $file->read($request, $size);
    return unless $bytes == $size;
    $request = thaw($request);

    return Plack::VCR::Interaction->new(
        request => $request,
    );
}

1;

# ABSTRACT:

__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=cut
