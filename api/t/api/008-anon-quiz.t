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

my $res_first = $t->post_ok(
    '/anon-questionnaires/new',
    form => {
        token     => 'validtoken',  questionnaire_id => 2,
        remote_id => 'test-remote', init_responses   => '{"foo":"bar"}'
    }
)->status_is(200, 'valid response')->tx->res->json;
ok $res_first->{quiz_session}{session_id}, 'has session_id';

is trace_popall(), 'anon_new_quiz_session:created', 'quiz_session was created';

$t->get_ok(
    '/anon-questionnaires/history',
    form => {
        token      => 'validtoken',
        session_id => 0,
    }
)->status_is(400, 'not valid session_id')->json_is('/field', 'session_id');

my $res_history = $t->get_ok(
    '/anon-questionnaires/history',
    form => {
        token      => 'validtoken',
        session_id => $res_first->{quiz_session}{session_id},
    }
)->status_is(200, 'valid response')->tx->res->json;

is trace_popall(), 'anon_load_quiz_session:loaded', 'quiz_session was loaded';
is $res_first, $res_history, 'is the same response';

my $input = $res_first->{quiz_session}{current_msgs}[-1];
ok $input, 'has input';
is $input->{type},    'onlychoice', 'is onlychoice';
ok $input->{ref},     'has ref';
is $input->{content}, 'choose one', 'content ok';
is $input->{code},    'chooseone',  'has code (because it is anon)';

# responde o choose one
my $res_second = $t->post_ok(
    '/anon-questionnaires/process',
    form => {
        token         => 'validtoken',
        session_id    => $res_first->{quiz_session}{session_id},
        $input->{ref} => 0,
    }
)->status_is(200, 'valid response')->tx->res->json;

$input = $res_second->{quiz_session}{current_msgs}[-1];
ok $input, 'has input';
is $input->{type},    'button', 'is button';
ok $input->{ref},     'has ref';
is $input->{content}, 'fim',       'content ok';
is $input->{label},   'Enviar',    'label ok';
is $input->{code},    'botao_fim', 'has code (because it is anon)';


my $res_end = $t->post_ok(
    '/anon-questionnaires/process',
    form => {
        token         => 'validtoken',
        session_id    => $res_first->{quiz_session}{session_id},
        $input->{ref} => 1,
    }
)->status_is(200, 'valid response')->tx->res->json;

is $res_end->{quiz_session}{finished}, 1, 'finished';

$t->get_ok(
    '/anon-questionnaires/history',
    form => {
        token      => 'validtoken',
        session_id => $res_first->{quiz_session}{session_id},
    }
)->status_is(200, 'full history is 200 after finished, but is missing content');


done_testing();
