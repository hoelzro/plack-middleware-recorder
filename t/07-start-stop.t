use strict;
use warnings;
use lib 't/lib';

use Plack::Builder;
use Plack::Recorder::TestUtils;
use Plack::Test;
use Test::More tests => 7;

my ( $tempfile, $app ) = Plack::Recorder::TestUtils->get_app;

my @request_paths;
$app = builder {
    enable sub {
        my ( $app ) = @_;

        return sub {
            my ( $env ) = @_;

            push @request_paths, $env->{'PATH_INFO'};

            return $app->($env);
        };
    };
    $app;
};


test_psgi $app, sub {
    my ( $cb ) = @_;

    $cb->(GET '/foo');
    $cb->(GET '/recorder/stop');
    $cb->(GET '/bar');
    $cb->(GET '/recorder/start');
    $cb->(GET '/baz');
};

my $vcr = Plack::VCR->new(filename => $tempfile);
my $interaction;
my $req;

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/foo';

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/baz';

$interaction = $vcr->next;
ok !$interaction;

is_deeply \@request_paths, ['/foo', '/bar', '/baz'];
