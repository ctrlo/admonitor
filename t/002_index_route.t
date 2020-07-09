use strict;
use warnings;

use Admonitor;
use Test::More tests => 2;
use Plack::Test ();
use HTTP::Request::Common 'GET';

my $app = Admonitor->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );

ok( $res->is_redirect, '[GET /] redirects' )
    or diag $res->as_string;
