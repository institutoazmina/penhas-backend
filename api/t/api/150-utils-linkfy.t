use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Test2::V0;
use Penhas::Utils qw/linkfy/;
use Mojo::URL;

sub _extract_href {
    my ($html) = @_;
    my ($href) = $html =~ /<a href="([^"]+)">/;
    return $href;
}

subtest 'linkfy sanitizes href with embedded html' => sub {
    my $input = q{https://azmina.com.br/colunas/orfaos-do-<span style="color:red">feminicidio-como-a-vida-continua/};
    my $html  = linkfy($input);
    my $href  = _extract_href($html);

    ok(defined $href, 'href extracted');
    unlike($href, qr/[<>]/, 'href has no angle brackets');

    my $url = Mojo::URL->new($href);
    ok($url->is_abs, 'href is absolute');
    is(lc($url->scheme // ''), 'https', 'href uses https scheme');
};

subtest 'linkfy keeps absolute url when source starts with www' => sub {
    my $input = q{www.azmina.com.br/colunas/};
    my $html  = linkfy($input);
    my $href  = _extract_href($html);

    ok(defined $href, 'href extracted');
    is($href, 'https://www.azmina.com.br/colunas/', 'www link was normalized to absolute https url');
};

subtest 'linkfy avoids invalid absolute href after sanitization' => sub {
    my $input = q{https://<span style="color:red">};
    my $html  = linkfy($input);

    unlike($html, qr/<a href="/, 'invalid href was not linkified');
};

done_testing;
