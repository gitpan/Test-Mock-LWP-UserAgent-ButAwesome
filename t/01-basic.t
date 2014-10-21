use strict;
use warnings FATAL => 'all';

use Test::More tests => 36;
use Test::NoWarnings 1.04 ':early';
use Test::Deep;
use Storable 'freeze';

# simulates real code that we are testing
{
    package MyApp;
    use strict;
    use warnings;

    use URI;
    use HTTP::Request::Common;
    use LWP::UserAgent;

    # in real code, you might want a Moose lazy _build_ua sub for this
    our $useragent = LWP::UserAgent->new;

    sub send_to_url
    {
        my ($self, $method, $base_url, $port, $path, %params) = @_;

        my $uri = URI->new($base_url);
        $uri->port($port);
        $uri->query_form(%params) if keys %params and $method eq 'GET';
        $uri->path($path);

        my $request_sub = HTTP::Request::Common->can($method);
        my $request = $request_sub->(
            $uri,
            $method eq 'POST' ? \%params : (),
        );

        my $response = $useragent->request($request);
    }
}

use Test::Mock::LWP::UserAgent::ButAwesome;
my $class = 'Test::Mock::LWP::UserAgent::ButAwesome';

cmp_deeply(
    $class,
    methods(
        last_http_request_sent => undef,
        last_http_response_received => undef,
    ),
    'initial state (class)',
);


cmp_deeply(
    $class->new,
    all(
        isa($class),
        isa('LWP::UserAgent'),
        methods(
            last_http_request_sent => undef,
            last_http_response_received => undef,
        ),
        noclass(superhashof({
            __last_http_request_sent => undef,
            __last_http_response_received => undef,
            __response_map => [],
        })),
    ),
    'initial state (object)',
);

# class methods
{
    $class->map_response('http://foo:3001/success?a=1', HTTP::Response->new(201));
    $class->map_response(qr{foo.+success}, HTTP::Response->new(200));
    $class->map_response(qr{foo.+fail}, HTTP::Response->new(500));
    $class->map_response(sub { shift->method eq 'HEAD' }, HTTP::Response->new(304));
    $class->map_response(HTTP::Request->new('DELETE', 'http://foo:3003/blah'), HTTP::Response->new(202));;

    $MyApp::useragent = $class->new;

    foreach my $test (
        [ 'regexp success', 'GET', 'http://foo', 3000, 'success', { a => 1 },
            str('http://foo:3000/success?a=1'), '', 200 ],
        [ 'regexp fail', 'POST', 'http://foo', 3000, 'fail', { a => 1 },
            str('http://foo:3000/fail'), 'a=1', 500 ],
        [ 'string success', 'GET', 'http://foo', 3001, 'success', { a => 1 },
            str('http://foo:3001/success?a=1'), '', 201 ],
        [ 'subref redirect', 'HEAD', 'http://foo',  3002, 'blah', {},
            str('http://foo:3002/blah'), '', 304 ],
        [ 'literal object', 'DELETE', 'http://foo', 3003, 'blah', {},
            str('http://foo:3003/blah'), '', 202 ],
    )
    {
        test_send_request(@$test);
    }
}

# object methods
{
    $MyApp::useragent = $class->new;

    cmp_deeply(
        $MyApp::useragent,
        all(
            isa($class),
            isa('LWP::UserAgent'),
            methods(
                last_http_request_sent => undef,
                last_http_response_received => undef,
            ),
            noclass(superhashof({
                __last_http_request_sent => undef,
                __last_http_response_received => undef,
                __response_map => [],
            })),
        ),
        'initial state of object after sending requests with another instance',
    );

    # create one new mapping on this instance, and confirm it takes priority
    $MyApp::useragent->map_response(qr{foo.+fail}, HTTP::Response->new(401));
    test_send_request(
        'regexp fail', 'POST', 'http://foo', 3000, 'fail', { a => 1 },
            str('http://foo:3000/fail'), 'a=1', 401,  # globally, returning 500
    );

    $MyApp::useragent->unmap_all('this_instance_only');

    test_send_request(
        'global mappings are still in effect', 'GET', 'http://foo', 3000, 'success', { a => 1 },
            str('http://foo:3000/success?a=1'), '', 200,
    );

    $MyApp::useragent->unmap_all;

    test_send_request(
        'all mappings are now gone', 'GET', 'http://foo', 3000, 'success', { a => 1 },
            str('http://foo:3000/success?a=1'), '', 404,
    );
}

sub test_send_request
{
    my ($name, $method, $uri_base, $port, $path, $params,
        $expected_uri, $expected_content, $expected_code) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    note "\n", $name;

    my $response = MyApp->send_to_url($method, $uri_base, $port, $path, %$params);

    # response is what we stored in the useragent
    isa_ok($response, 'HTTP::Response');
    is(
        freeze($MyApp::useragent->last_http_response_received),
        freeze($response),
        'last_http_response_received',
    );

    cmp_deeply(
        $MyApp::useragent->last_http_request_sent,
        all(
            isa('HTTP::Request'),
            methods(
                uri => $expected_uri,
            ),
        ),
        "$name request",
    );

    cmp_deeply(
        $response,
        methods(
            code => $expected_code,
        ),
        "$name response",
    );
}

