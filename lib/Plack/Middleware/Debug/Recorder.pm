## no critic (RequireUseStrict)
package Plack::Middleware::Debug::Recorder;

## use critic (RequireUseStrict)
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

# ABSTRACT: Debug panel to communicate with the Recorder middleware

__END__

=head1 SYNOPSIS

  builder {
    enable 'Recorder', output => $output;
    enable 'Debug', panels => [qw/Recorder/];
    $app;
  };

=head1 DESCRIPTION

This debug panel displays the current state of the recorder middleware (whether or not it's currently recording),
and provides some buttons for turning recording on or off.

=head1 SEE ALSO

L<Plack::Middleware::Recorder>, L<Plack::Middleware::Debug>

=cut
