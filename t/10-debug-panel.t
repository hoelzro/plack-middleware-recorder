use strict;
use warnings;
use lib 't/lib';

use HTML::TreeBuilder;
use List::MoreUtils qw(part);
use Plack::Builder;
use Plack::Recorder::TestUtils;
use Plack::Test;
use Test::More tests => 2;

sub test_panel {
    my ( $res, $expected_active, $expected_start, $expected_stop ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $tree    = HTML::TreeBuilder->new_from_content($res->content);
    my $panel   = $tree->look_down(
        _tag  => 'div',
        class => 'panelContent',
        sub {
            my ( $e ) = @_;

            my $title = $e->look_down(_tag => 'div',
                class => 'plDebugPanelTitle');
            $title && $title->look_down(_tag => 'h3')->as_text =~ /Recorder/;
        },
    );
    subtest 'panel test', sub {
        ok $panel, 'debugging panel was found';
        my $content = $panel->look_down(_tag => 'div',
            class => 'plDebugPanelContent');
        my $status = $content->look_down(_tag => 'div',
            class => 'plRecorderStatus');
        ok $status;
        if($expected_active) {
            like $status->as_text, qr/Request recording is ON/;
        } else {
            like $status->as_text, qr/Request recording is OFF/;
        }
        my $start;
        my $stop;
        my $links = [ $content->look_down(_tag => 'a') ];

        ( $start, $links ) = part { $_->attr('href') eq $expected_start ? 0 : 1 } @$links;
        $start = $start->[0];
        ok $start, 'start recording link was found';
        like $start->as_text, qr/Start Recording/;
        ( $stop, $links ) = part { $_->attr('href') eq $expected_stop ? 0 : 1 } @$links;
        $stop = $stop->[0];
        ok $stop, 'stop recording link was found';
        like $stop->as_text, qr/Stop Recording/;

        ok !$links, 'no extra links were found';

        done_testing;
    };
    $tree->delete;
}

my $tempfile = File::Temp->new;
close $tempfile;

my $html = <<HTML;
<html>
  <head>
    <title>Plack::Middleware::Recorder Test</title>
  </head>
  <body>
    Hi from PSGI!
  </body>
</html>
HTML

my $app = builder {
    enable 'Debug', panels => [qw/Recorder/];
    enable 'Recorder', output => $tempfile->filename;
    sub {
        [ 200, ['Content-Type' => 'text/html'], [$html] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res;

    $res = $cb->(GET '/');
    test_panel($res, 1, '/recorder/start', '/recorder/stop');
    $cb->(GET '/recorder/stop');
    $res = $cb->(GET '/');
    test_panel($res, 0, '/recorder/start', '/recorder/stop');
};
