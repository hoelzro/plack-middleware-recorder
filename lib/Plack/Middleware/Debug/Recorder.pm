package Plack::Middleware::Debug::Recorder;

use strict;
use warnings;
use parent 'Plack::Middleware::Debug::Base';

sub run {
    my ( $self, $env, $panel ) = @_;

    $panel->title('Recorder');

    return sub {
        my ( $res ) = @_;

        unless(exists $env->{'Plack::Middleware::Recorder.active'}) {
            $panel->disabled(1);
            return;
        }

        my $status = $env->{'Plack::Middleware::Recorder.active'}
            ? 'ON'
            : 'OFF';

        my $color     = $status eq 'ON' ? 'green' : 'red';
        my $start_url = $env->{'Plack::Middleware::Recorder.start_url'};
        my $stop_url  = $env->{'Plack::Middleware::Recorder.stop_url'};

        my $content = <<HTML;
<div class='plRecorderStatus'>
Request recording is <span style='color: $color'>$status</span>
</div>
<div>
    <button class='plRecorderStart'>Start Recording</button>
    <br />
    <button class='plRecorderStop'>Stop Recording</button>
</div>
<script type='text/javascript'>
    (function(\$) {
        \$(document).ready(function() {
            \$('.plRecorderStart').click(function() {
                \$.get('$start_url', function(data) {
                    \$('.plRecorderStatus').html('Request recording is <span style="color: green">ON</span>');
                });
            });
            \$('.plRecorderStop').click(function() {
                \$.get('$stop_url', function(data) {
                    \$('.plRecorderStatus').html('Request recording is <span style="color: red">OFF</span>');
                });
            });
        });
    })(jQuery);
</script>
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
