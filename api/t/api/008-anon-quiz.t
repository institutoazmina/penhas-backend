use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;
my $t = test_instance;
my $json;

$ENV{FILTER_QUESTIONNAIRE_IDS} = '2';
$ENV{ANON_QUIZ_SECRET}         = 'validtoken';

$t->get_ok('/anon-questionnaires')->status_is(400, 'missing token')->json_is('/field', 'token')
  ->json_is('/reason', 'is_required');

$t->get_ok(
    '/anon-questionnaires',
    form => {token => 'wrong'}
)->status_is(400, 'invalid token')->json_is('/field', 'token')->json_is('/reason', 'invalid');

$t->get_ok(
    '/anon-questionnaires',
    form => {token => 'validtoken'}
)->status_is(200, 'valid response')->json_is('/questionnaires/0/name', 'anon-test')
  ->json_is('/questionnaires/0/id', 2, 'loaded correct questionnaire');


done_testing();
