package Plack::Middleware::Debug::Recorder;

use strict;
use warnings;
use parent 'Plack::Middleware::Debug::Base';

sub run {
    my ( $self, $env, $panel ) = @_;

    $panel->title('Recorder');

    return sub {
        my ( $res ) = @_;

        my $status = $env->{'Plack::Middleware::Recorder.active'}
            ? 'ON'
            : 'OFF';

        my $color = $status eq 'ON' ? 'green' : 'red';

        my $content = <<HTML;
<div class='plRecorderStatus'>
Request recording is <span style='color: $color'>$status</span>
</div>
<div>
    <a href='/recorder/start'>Start Recording</a>
    <br />
    <a href='/recorder/stop'>Stop Recording</a>
</div>
HTML

        $panel->content($content);
    };
}

1;

__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=cut
