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

# ABSTRACT: Represents a single HTTP interaction

__END__

=head1 DESCRIPTION

Retrieved from L<Plack::VCR/next>; objects of this
class currently only contain an L<HTTP::Request>.

=head1 METHODS

=head2 request

Returns the L<HTTP::Request> for this interaction.

=head1 SEE ALSO

L<Plack::VCR>

=begin comment

=over

=item new

=back

=end comment

=cut
