use strict;
use warnings;
use lib 't/lib';

use Plack::Recorder::TestUtils;
use Plack::Test;
use Test::More tests => 7;

my ( $tempfile, $app ) = Plack::Recorder::TestUtils->get_app;

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
