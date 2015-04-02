use strict;
use warnings;

use HTTP::Request::Common;
use File::Temp;
use Plack::Builder;
use Plack::VCR;
use Plack::Test;
use Test::More;
use IO::File;
use Fcntl qw(:flock);
use Plack::Middleware::Recorder;

my @tests = ( [ 'concurrency off',
                sub { },
                sub { ok(! is_flocked($_[0]), 'file is not locked during write') }
              ],
              [ 'multithread concurrency',
                 sub { $_[0]->{'psgi.multithread'} = 1 },
                 sub { ok(is_flocked($_[0]), 'file is locked during write') }
              ],
              [ 'multitprocess concurrency',
                sub { $_[0]->{'psgi.multiprocess'} = 1 },
                sub { ok(is_flocked($_[0]), 'file is locked during write') }
              ],
);

if (Plack::Middleware::Recorder::_has_flock()) {
    plan tests => scalar(@tests);
} else {
    plan skip_all => 'flock not supported on this system';
}

foreach my $test_desc ( @tests ) {
    my($desc, $enable_multi, $lockfile_test) = @$test_desc;

    subtest $desc => sub {
        plan tests => 6;

        my $tempfile = File::Temp->new;
        close $tempfile;

        # Intercept Recorder's write to the output file and test
        # the locking status
        my $orig_io_file_write = IO::File->can('write');
        no warnings 'once';
        local *IO::File::write = sub {
            my $fh = shift;
            $lockfile_test->($tempfile->filename);
            $fh->$orig_io_file_write(@_);
        };

        my $app = builder {
            enable concurrency_setter_middleware($enable_multi);
            enable 'Recorder', output => $tempfile->filename;
            sub {
                [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
            };
        };

        test_psgi $app, sub {
            my ( $cb ) = @_;

            ok(! is_flocked($tempfile->filename), 'Before request, file is not locked');
            $cb->(GET '/');
            ok(! is_flocked($tempfile->filename), 'After request, file is not locked');
        };

        my $vcr = Plack::VCR->new(filename => $tempfile->filename);
        my $interaction = $vcr->next;
        ok($interaction, 'Got interaction');
        my $req = $interaction->request;
        is($req->method, 'GET', 'request method was GET');
        is($req->uri, '/', 'request URI was /');
    };
};

sub concurrency_setter_middleware {
    my $enable_multi = shift;
    return sub {
        my $app = shift;
        sub {
            my $env = shift;
            $enable_multi->($env);
            $app->($env);
        };
    };
}

sub is_flocked {
    my $filename = shift;
    my $fh = IO::File->new($filename, 'a');
    my $not_locked = flock($fh, LOCK_EX | LOCK_NB);
    return ! $not_locked;
}
