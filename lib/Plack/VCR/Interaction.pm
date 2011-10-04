package Plack::VCR::Interaction;

use strict;
use warnings;

use Plack::Util::Accessor qw/request/;

sub new {
    my ( $class, %opts ) = @_;

    return bless \%opts, $class;
}

1;

__END__

# ABSTRACT:

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=cut
