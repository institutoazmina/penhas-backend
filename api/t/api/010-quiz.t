use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;
my $t = test_instance;
my $json;

my ($session, $user_id) = get_user_session('24115775670');
my $cliente = get_schema2->resultset('Cliente')->find($user_id);

$cliente->update(
    {
        modo_camuflado_ativo         => '0',
        modo_camuflado_atualizado_em => undef,
        modo_anonimo_ativo           => '0',
        modo_anonimo_atualizado_em   => undef,
    }
);

$ENV{FILTER_QUESTIONNAIRE_IDS} = '4,5';

app->schema2->resultset('ClientesQuizSession')->search(
    {
        'cliente_id' => $user_id,
    }
)->delete;

my $cadastro = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->tx->res->json;

is trace_popall(), 'clientes_quiz_session:created', 'clientes_quiz_session was created';

$json = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->json_has('/quiz_session/session_id')->tx->res->json;

ok((grep { $_->{code} eq 'quiz' } $json->{modules}->@*)   ? 1 : 0, 'has quiz');
ok((grep { $_->{code} eq 'tweets' } $json->{modules}->@*) ? 0 : 1, 'has not tweets');

#json_has('/modules/quiz')->json_hasnt('/modules/tweets');
is trace_popall(), 'clientes_quiz_session:loaded', 'clientes_quiz_session was just loaded';

my $first_session_id;
subtest_buffered 'Testar envio de campo boolean com valor invalido + interpolation de variaveis no intro' => sub {
    $first_session_id = $cadastro->{quiz_session}{session_id};
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


    is $second_msg->{content}, 'intro1',                 'question intro is working';
    is $third_msg->{content},  'HELLOQuiz User Name!',   'question intro interpolation is working';
    is $input_msg->{content},  'yesno question☺️⚠️👍👭🤗🤳', 'yesno question question is present';
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

    my $db_session = app->schema2->resultset('ClientesQuizSession')->search(
        {
            'id' => $cadastro->{quiz_session}{session_id},
        }
    )->next;
    is(from_json($db_session->responses)->{freetext}, $choose_rand, 'responses is updated with random text');
};

subtest_buffered 'group de questoes boolean' => sub {

    $json = $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    my $first_msg = $json->{quiz_session}{current_msgs}[0];
    my $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{content}, 'Question A', 'NO intro text';
    is $input_msg->{type},    'yesno',      'yesno type';

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
            $field_ref => $options->[0]{index},
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{type},    'displaytext',      'just a text';
    is $first_msg->{content}, 'displaytext flow', 'context of text';

    is $input_msg->{content},            'btn_responder_zero',        'button has content';
    is $input_msg->{action},             'botao_tela_modo_camuflado', 'action for button is botao_tela_modo_camuflado';
    is $input_msg->{type},               'button',                    'is a button';
    is $input_msg->{ending_action_text}, 'Modo camuflado ativado',    'text ok';
    is $input_msg->{ending_cancel_text}, 'Tutorial cancelado',        'text cancel';
    is $input_msg->{label},              'Visualizar',                'text label';

    $cliente->discard_changes;
    is $cliente->modo_anonimo_ativo, 0, 'modo_anonimo_ativo=false';

    # apertando o botao "botao_tela_modo_camuflado" = 0
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 0,
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $cliente->discard_changes;
    is $cliente->modo_anonimo_ativo, 1, 'modo_anonimo_ativo=TRUE';
    ok $cliente->modo_anonimo_atualizado_em, 'modo_anonimo_atualizado_em is date';

    is $cliente->modo_camuflado_ativo, 0, 'modo_camuflado_ativo=FALSE';
    ok $cliente->modo_camuflado_atualizado_em, 'modo_camuflado_atualizado_em is date';

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{type},    'displaytext',         'just a text';
    is $first_msg->{content}, 'btn_camuflado1=PASS', 'expected pass';

    is $input_msg->{type},               'button',                    'is a button';
    is $input_msg->{content},            'btn_responder_com1',        'button has content';
    is $input_msg->{action},             'botao_tela_modo_camuflado', 'button action camuflado again';
    ok $input_msg->{ending_action_text}, 'has ending_action_text';
    ok $input_msg->{ending_cancel_text}, 'has ending_cancel_text';
    ok $input_msg->{label},              'has label';

    # apertando o botao "botao_tela_modo_camuflado" = 1
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 1,
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{type},    'displaytext',          'just a text';
    is $first_msg->{content}, 'btn_camuflado2=PASS2', 'expected pass2';

    $cliente->discard_changes;
    is $cliente->modo_anonimo_ativo, 1, 'modo_anonimo_ativo=TRUE';
    ok $cliente->modo_anonimo_atualizado_em, 'modo_anonimo_atualizado_em is date';

    is $cliente->modo_camuflado_ativo, 1, 'modo_camuflado_ativo=TRUE';
    ok $cliente->modo_camuflado_atualizado_em, 'modo_camuflado_atualizado_em is date';

    is $input_msg->{type},    'onlychoice', 'is a onlychoice';
    is $input_msg->{content}, 'choose one', 'onlychoice has content';
    is $input_msg->{action},  undef,        'button action is undef [not a button]';
    is $input_msg->{options}[0]{display}, 'option a', 'options a is ok';
    is $input_msg->{options}[1]{display}, 'option b', 'options a is ok';
    is $input_msg->{options}[0]{index},   0,          'index a is ok';
    is $input_msg->{options}[1]{index},   1,          'index b is ok';


    # apertando o botao "onlychoise" = 1
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 1,
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;
    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $input_msg->{type},    'button', 'is a button';
    is $input_msg->{content}, 'final',  'button has content';
    is $input_msg->{action},  'none',   'button action is none [btn-fim]';

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
    is scalar @$prev_msgs, 13, '13 prev questions';

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

    # teste do profile
    $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200, 'profile is ok')->json_is('/user_profile/modo_camuflado_ativo', 1, 'modo_camuflado_ativo is 1')
      ->json_is('/user_profile/modo_anonimo_ativo', 1, 'modo_anonimo_ativo is 1');


    my $session   = get_schema2->resultset('ClientesQuizSession')->find($cadastro->{quiz_session}{session_id});
    my $responses = from_json($session->responses);

    is $responses->{btn_camuflado1},        0,                           'ok value';
    is $responses->{btn_camuflado1_action}, "botao_tela_modo_camuflado", 'ok value';
    is $responses->{btn_camuflado2},        1,                           'ok value';
    is $responses->{btn_camuflado2_action}, "botao_tela_modo_camuflado", 'ok value';
    is $responses->{btn_fim},               1,                           'ok value';
    is $responses->{btn_fim_action},        "none",                      'ok value';
    is $responses->{chooseone},             "b",                         'ok value';
    is $responses->{freetext},              $choose_rand, 'ok value';
    is $responses->{groupq},                4,     'ok value';
    is $responses->{groupq_2},              "N",   'ok value';
    is $responses->{groupq_4},              "Y",   'ok value';
    is $responses->{groupq_reb},            "Y",   'ok value';
    is $responses->{groupq_refa},           "N",   'ok value';
    is $responses->{skill},                 "[0]", 'ok value';
    ok $responses->{start_time},            'has value';
    is $responses->{yesno1},                "Y", 'ok value';


};

$cadastro = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->json_is('/quiz_session', undef)->tx->res->json;

subtest_buffered 'reiniciando o quiz' => sub {

    my $cliente = app->schema2->resultset('Cliente')->search(
        {
            'id' => $user_id,
        }
    )->first;

    is $cliente->quiz_detectou_violencia, 1, 'quiz_detectou_violencia=1';
    my $json = $t->get_ok(
        '/me/chats',
        {'x-api-key' => $session},
      )->status_is(200, 'busca session')    #
      ->json_is(
        '/assistant/quiz_session/session_id', $cliente->assistant_session_id(),
        'quiz_session/session_id match expected'
      )                                     #
      ->json_like(
        '/assistant/quiz_session/current_msgs/0/content', qr/identifiquei que você estava em situação de risco./,
        'realmente passou pelo fluxo de risco'
      )                                     #
      ->json_is('/assistant/quiz_session/current_msgs/1/type', 'yesno', 'sim/nao')->tx->res->json;
    $json = $json->{assistant};

    # apertando o botao "reset_questionnaire" = N
    my $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    is $field_ref, 'reset_questionnaire', 'botao esperado';
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $json->{quiz_session}{session_id},
            $field_ref => 'N',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    my $first_msg = $json->{quiz_session}{current_msgs}[0];
    my $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{type},      'button',  'button';
    like $first_msg->{content}, qr/única/, 'unica função';

    # apertando o botao "BT_RETURN" = 1
    $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $json->{quiz_session}{session_id},
            BT_RETURN  => 1,
        }
    )->status_is(200)->json_is('/quiz_session/finished', 1)
      ->json_is('/quiz_session/end_screen', '/mainboard?page=chat');

    # apertando o botao "reset_questionnaire" = Y
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $json->{quiz_session}{session_id},
            $field_ref => 'Y',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    is $first_msg->{type},    'displaytext', 'just a text';
    is $first_msg->{content}, 'intro1',      'intro text';

    like $json->{quiz_session}{session_id}, qr/^\d+$/a, 'just numbers';
    isnt $json->{quiz_session}{session_id}, $first_session_id, 'not the same as before';
};

done_testing();
