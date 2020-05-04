use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;
my $t = test_instance;
my $json;

my ($session, $user_id) = get_user_session('30085070343');

$ENV{FILTER_QUESTIONNAIRE_IDS} = '4,5';

my $quiz_sessions = app->directus->search(
    table => 'clientes_quiz_session',
    form  => {
        'filter[cliente_id][eq]' => $user_id,
    }
);

foreach ($quiz_sessions->{data}->@*) {
    app->directus->delete(
        table => 'clientes_quiz_session',
        id    => $_->{id}
    );
}

my $cadastro = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->tx->res->json;

is trace_popall(), 'clientes_quiz_session:created', 'clientes_quiz_session was created';

$t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->json_has('/quiz_session/session_id')->json_is('/modules/0', 'quiz');
is trace_popall(), 'clientes_quiz_session:loaded', 'clientes_quiz_session was just loaded';


subtest_buffered 'Testar envio de campo boolean com valor invalido + interpolation de variaveis no intro' => sub {
    my $field_ref = $cadastro->{quiz_session}{current_msgs}[-1]{ref};
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'X',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    my $first_msg  = $json->{quiz_session}{current_msgs}[0];
    my $second_msg = $json->{quiz_session}{current_msgs}[1];
    my $third_msg  = $json->{quiz_session}{current_msgs}[2];
    my $input_msg  = $json->{quiz_session}{current_msgs}[-1];
    like $first_msg->{content}, qr/$field_ref.+deve ser Y ou N/, "$field_ref nao pode ser X";
    is $first_msg->{style},     'error',                         'type is error';


    is $second_msg->{content}, 'intro1',          'question intro is working';
    is $third_msg->{content},  'HELLOtest name!', 'question intro interpolation is working';
    is $input_msg->{content},  'yesno question',  'yesno question question is present';
};

my $choose_rand = rand;
subtest_buffered 'Seguindo fluxo ate o final usando caminho Y' => sub {
    my $field_ref = $cadastro->{quiz_session}{current_msgs}[-1]{ref};
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'Y',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;


    my $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $input_msg->{content}, 'question for YES', 'flow is working!';
    is $input_msg->{type},    'text',             'flow is working!';

    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id        => $cadastro->{quiz_session}{session_id},
            $input_msg->{ref} => $choose_rand,
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    my $db_session = app->directus->search_one(
        table => 'clientes_quiz_session',
        form  => {
            'filter[id][eq]' => $cadastro->{quiz_session}{session_id},

        }
    );

    is $db_session->{responses}{freetext}, $choose_rand, 'responses is updated with random text';
};

subtest_buffered 'group de questoes boolean' => sub {

    $json = $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    my $first_msg = $json->{quiz_session}{current_msgs}[0];
    my $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{content}, 'a group of yes no questions will start now', 'group question intro text';

    is $input_msg->{type},    'yesno',      'yesno type';
    is $input_msg->{content}, 'Question A', 'yesno type';

    my $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'N',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];
    is $first_msg, $input_msg, 'just the new message, no intro';

    is $input_msg->{type},    'yesno',      'yesno type';
    is $input_msg->{content}, 'Question B', 'yesno type';

    # respondendo a segunda (e ultima) boolean do grupo
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'Y',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg, $input_msg, 'just the new message, no intro';

    # respondendo o multiplechoices
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    my $options = $json->{quiz_session}{current_msgs}[-1]{options};
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => (join ',', $options->[0]{index}, $options->[-1]{index}),
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{type},    'displaytext',       'just a text';
    is $first_msg->{content}, 'autocontinue flow', 'context of text';

    is $input_msg->{type},    'button',                    'is a button';
    is $input_msg->{content}, 'btn1',                      'button has content';
    is $input_msg->{action},  'botao_tela_modo_camuflado', 'action for button is botao_tela_modo_camuflado';

    # apertando o botao "botao_tela_modo_camuflado"
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 1,
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;
    $input_msg = $json->{quiz_session}{current_msgs}[-1];
    is $input_msg->{type},    'button',             'is a button';
    is $input_msg->{content}, 'btn2',               'button has content';
    is $input_msg->{action},  'botao_tela_socorro', 'button action is botao_tela_socorro';

    my $prev_msgs = $t->get_ok(
        '/me',
        {'x-api-key' => $session},
    )->status_is(200)->json_has('/quiz_session')->tx->res->json->{quiz_session}{prev_msgs};

    foreach my $prev (@$prev_msgs) {
        if ($prev->{type} eq 'displaytext') {
            ok $prev->{content}, 'has content';
        }
        else {
            ok $prev->{display_response}, 'has display_response';
        }
    }
    is scalar @$prev_msgs, 10, '10 prev questions';

    # apertando o botao botao_tela_socorro
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 1,
        }
    )->status_is(200)->json_is('/quiz_session/finished', 1)
      ->json_is('/quiz_session/end_screen', "freetext=$choose_rand")->tx->res->json;

};

$cadastro = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->json_is('/quiz_session', undef)->tx->res->json;

use DDP;
p $cadastro;

done_testing();