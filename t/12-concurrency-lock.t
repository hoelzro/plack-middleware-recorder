use strict;
use warnings;

use HTTP::Request::Common;
use File::Temp;
use Plack::Builder;
use Plack::VCR;
use Plack::Test;
use Test::More;
use IO::File;

my @tests = ( [ 'concurrency off',
                sub { },
                sub { ok(! -f $_[0], 'lock file does not exist during write') }
              ],
              [ 'multithread concurrency',
                 sub { $_[0]->{'psgi.multithread'} = 1 },
                 sub { ok(-f $_[0], 'lock file exists during write') }
              ],
              [ 'multitprocess concurrency',
                sub { $_[0]->{'psgi.multiprocess'} = 1 },
                sub { ok(-f $_[0], 'lock file exists during write') }
              ],
);

plan tests => scalar(@tests);

foreach my $test_desc ( @tests ) {
    my($desc, $enable_multi, $lockfile_test) = @$test_desc;

    subtest $desc => sub {
        plan tests => 6;

        my $tempfile = File::Temp->new;
        close $tempfile;

        my $expected_lock_file = "${tempfile}.lock";

        # Intercept Recorder's write to the output file and test
        # the locking status
        my $orig_io_file_write = IO::File->can('write');
        no warnings 'once';
        local *IO::File::write = sub {
            my $fh = shift;
            $lockfile_test->($expected_lock_file);
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

            ok(! -f $expected_lock_file, 'Before request, lock file does not exist');
            $cb->(GET '/');
            ok(! -f $expected_lock_file, 'After request, lock file does not exist');
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
