use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Test2::V0;
use Penhas::Test;

my $t = test_instance;

subtest 'API responses include security headers' => sub {

    $t->get_ok('/web/faq')->status_is(200);

    my $headers = $t->tx->res->headers;

    is $headers->header('X-Frame-Options'),       'DENY',    'X-Frame-Options is DENY';
    is $headers->header('X-Content-Type-Options'), 'nosniff', 'X-Content-Type-Options is nosniff';
    is $headers->header('X-XSS-Protection'),       '0',       'X-XSS-Protection is 0 (modern recommendation)';

    like $headers->header('Content-Security-Policy'), qr/default-src 'self'/,
      'CSP includes default-src self';
    like $headers->header('Content-Security-Policy'), qr/frame-ancestors 'none'/,
      'CSP includes frame-ancestors none';

    is $headers->header('Referrer-Policy'), 'strict-origin-when-cross-origin',
      'Referrer-Policy is strict-origin-when-cross-origin';

    like $headers->header('Permissions-Policy'), qr/geolocation=\(\)/,
      'Permissions-Policy restricts geolocation';
    like $headers->header('Permissions-Policy'), qr/camera=\(\)/,
      'Permissions-Policy restricts camera';
    like $headers->header('Permissions-Policy'), qr/microphone=\(\)/,
      'Permissions-Policy restricts microphone';
};

subtest 'security headers present on termos-de-uso' => sub {

    $t->get_ok('/web/termos-de-uso')->status_is(200);

    my $headers = $t->tx->res->headers;

    is $headers->header('X-Frame-Options'),       'DENY',    'X-Frame-Options on termos-de-uso';
    is $headers->header('X-Content-Type-Options'), 'nosniff', 'X-Content-Type-Options on termos-de-uso';
};

subtest 'Cache-Control defaults to no-store for API responses' => sub {

    $t->get_ok('/web/faq')->status_is(200);

    is $t->tx->res->headers->cache_control, 'no-store',
      'Cache-Control is no-store by default';
};

subtest 'HSTS header is absent without HTTPS' => sub {

    $t->get_ok('/web/faq')->status_is(200);

    my $hsts = $t->tx->res->headers->header('Strict-Transport-Security');
    ok !defined $hsts, 'HSTS header not set for plain HTTP request';
};

subtest 'HSTS header present when X-Forwarded-Proto is https' => sub {

    $t->get_ok('/web/faq', {'X-Forwarded-Proto' => 'https'})->status_is(200);

    like $t->tx->res->headers->header('Strict-Transport-Security'),
      qr/max-age=31536000/,
      'HSTS header set when proxied as HTTPS';

    like $t->tx->res->headers->header('Strict-Transport-Security'),
      qr/includeSubDomains/,
      'HSTS includes includeSubDomains directive';
};

done_testing;
