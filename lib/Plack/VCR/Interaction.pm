## no critic (RequireUseStrict)
package Plack::VCR::Interaction;

## use critic (RequireUseStrict)
use strict;
use warnings;

use Plack::Util::Accessor qw/request/;

sub new {
    my ( $class, %opts ) = @_;

    return bless \%opts, $class;
}

1;

__END__

# ABSTRACT: Represents a single HTTP interaction

=head1 DESCRIPTION

Retrieved from L<Plack::VCR/next>, objects of this
class currently only contain an L<HTTP::Request>.

=head1 METHODS

=head2 request

Returns the L<HTTP::Request> for this interaction.

=begin comment

=over

=item new

=back

=end comment

=cut
