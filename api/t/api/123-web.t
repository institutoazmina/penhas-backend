use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;
use Penhas::Test;

my $t = test_instance;

use DateTime;
use utf8;

my $schema2 = $t->app->schema2;

my $cats = $schema2->resultset('FaqTelaSobreCategoria')->search(
    {
        is_test => '1',
    }
);
$cats->search_related('faq_tela_sobres')->delete;
$cats->delete;
my $c2 = $cats->create(
    {
        title  => 'Cat2',
        sort   => 2,
        status => 'published',
    }
);
my $c1 = $cats->create(
    {
        title  => 'Cat1',
        sort   => 1,
        status => 'published',
    }
);

$c1->faq_tela_sobres->create(
    {
        title        => 'c1.a',
        content_html => 'content a',
        sort         => 2,
        status       => 'published',
    }
);

$c1->faq_tela_sobres->create(
    {
        title        => 'c1.b',
        content_html => 'content b',
        sort         => 3,
        status       => 'published',
    }
);

$c2->faq_tela_sobres->create(
    {
        title        => 'c2.a',
        content_html => 'content a 2',
        sort         => 1,
        status       => 'published',
    }
);

$t->get_ok(
    '/web/faq',
)->status_is(200, 'puxando faq');


done_testing();

exit;
