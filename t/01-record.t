use strict;
use warnings;

use HTTP::Request::Common;
use File::Temp;
use Plack::Builder;
use Plack::VCR;
use Plack::Test;
use Test::More tests => 16;

my $tempfile = File::Temp->new;
close $tempfile;

my $app = builder {
    enable 'Recorder', output => $tempfile->filename;
    sub {
        [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    $cb->(GET '/');
    $cb->(GET '/', 'X-Made-Up-Header' => 17);
    $cb->(POST '/foo', 'X-Made-Up-Header' => 17, Content => [
        first_name => 'Rob',
        last_name  => 'Hoelz',
        full_name  => 'Rob Hoelz',
    ]);
    $cb->(GET '/bar?name=Rob%20Hoelz');
};

my $vcr = Plack::VCR->new(filename => $tempfile->filename);
my $interaction;
my $req;

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/';

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/';
is $req->header('X-Made-Up-Header'), 17;

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'POST';
is $req->uri, '/foo';
is $req->header('X-Made-Up-Header'), 17;
is $req->content, 'first_name=Rob&last_name=Hoelz&full_name=Rob+Hoelz';

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/bar?name=Rob%20Hoelz';

$interaction = $vcr->next;
ok ! $interaction;

