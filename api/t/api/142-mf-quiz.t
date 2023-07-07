#!/usr/bin/perl
# HARNESS-CONFLICTS CHAT

use JSON;
use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;
use utf8;
use Penhas::Test;
use Penhas::Minion::Tasks::SendSMS;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;
use DateTime;
use Penhas::Minion::Tasks::NewNotification;

my $schema2 = $t->app->schema2;

my $now_datetime = DateTime->now()->datetime(' ');

AGAIN:
my $random_cpf   = random_cpf();
my $random_email = 'email' . $random_cpf . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf);

$ENV{FILTER_QUESTIONNAIRE_IDS} = '99999';
$ENV{SKIP_END_NEWS}            = '1';

$Penhas::Helpers::Cliente::NEW_TASK_TOKEN = 'new-task';

my @other_fields = (
    raca        => 'branco',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

my $nome_completo = 'test tarefa';

get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf_hashed  => cpf_hash_with_salt($random_cpf),
        dt_nasc     => '1994-01-31',
        nome_hashed => cpf_hash_with_salt(uc $nome_completo),
        situacao    => '',
    }
);

my ($cliente_id, $session, $cliente);

subtest_buffered 'Cadastro com sucesso' => sub {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => $nome_completo,
            apelido       => 'cliente A',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'ARUKEAS SS2',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero      => rand() > 0.5 ? 'Feminino' : 'MulherTrans',
            nome_social => 'foo bar',
        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    $session    = $res->{session};
    $cliente    = $schema2->resultset('Cliente')->find($cliente_id);
};

on_scope_exit { user_cleanup(user_id => [$cliente_id,]); };


$t->get_ok('/filter-skills', {'x-api-key' => $session})->status_is(200);

db_transaction {

    $ENV{ENABLE_MANUAL_FUGA} = 1;
    my $me_perfil = $t->get_ok(
        '/me',
        {'x-api-key' => $session},
        form => {},
    )->status_is(200, '')->tx->res->json;

    my $epoch_start = 0;

    my $me_tarefas = $t->get_ok(
        '/me/tarefas',
        {'x-api-key' => $session},
        form => {modificado_apos => $epoch_start},
    )->status_is(200, 'busca todas as tarefas')->tx->res->json;

    ok $me_tarefas->{mf_assistant}{quiz_session}{session_id}, 'has session-id';

    subtest_buffered 'iniciando o questionario' => sub {

        my $mf_sc = get_user_mf_sc($cliente_id);
        is $mf_sc->status,                        'onboarding', 'status is onboarding';
        is $mf_sc->current_clientes_quiz_session, undef,        'current_clientes_quiz_session is null';

        my $json = $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $me_tarefas->{mf_assistant}{quiz_session}{session_id},
            }
        )->status_is(200)->json_has('/quiz_session')->tx->res->json;

        $mf_sc->discard_changes;
        is $mf_sc->status, 'inProgress', 'status is inProgress';
        is $mf_sc->completed_questionnaires_id, [], 'no completed_questionnaires_id';

        my $first_msg  = $json->{quiz_session}{current_msgs}[0];
        my $input_msg  = $json->{quiz_session}{current_msgs}[-1];
        my $session_id = $json->{quiz_session}{session_id};
        my $field_ref  = $json->{quiz_session}{current_msgs}[-1]{ref};

        ok $session_id, 'has session';
        like $first_msg->{content}, qr/bem-vinda ao Manual de Fuga do PenhaS./, "msg de bem vindo";
        like $input_msg->{content}, qr/Separamos o conteúdo em quatro blocos/,  'escolha dos blocos';
        like $field_ref, qr/^OC/, 'OC=only choice';

        $json = $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $me_tarefas->{mf_assistant}{quiz_session}{session_id},
            }
        )->status_is(200)->json_has('/quiz_session')->tx->res->json;

        $first_msg = $json->{quiz_session}{current_msgs}[0];
        like $first_msg->{content}, qr/existe um manual de fuga em andamento./, "erro pq mandou o session ID errado";

        $json = $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $session_id,
                $field_ref => 0,
            }
        )->status_is(200)->json_has('/quiz_session')->tx->res->json;

        $input_msg  = $json->{quiz_session}{current_msgs}[-1];
        $session_id = $json->{quiz_session}{session_id};
        $field_ref  = $json->{quiz_session}{current_msgs}[-1]{ref};

        like $input_msg->{content}, qr/Você tem para onde ir?/, 'pergunta yesnomaybe';
        is $input_msg->{type},      'yesnomaybe',               'sim não talvez';

        ## chama o get do session no meio do quiz
        my $me_tarefas_v2 = $t->get_ok(
            '/me/tarefas',
            {'x-api-key' => $session},
            form => {modificado_apos => $epoch_start},
        )->status_is(200, 'busca todas as tarefas')->tx->res->json;

        $input_msg = $me_tarefas_v2->{mf_assistant}{quiz_session}{current_msgs}[-1];
        like $input_msg->{content}, qr/Você tem para onde ir?/, 'pergunta yesnomaybe';

        $mf_sc->discard_changes;
        is $mf_sc->status, 'inProgress', 'status is inProgress';
        is $mf_sc->completed_questionnaires_id, [7], 'completed b0';

        $json = $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $session_id,
                $field_ref => 'Y',
            }
        )->status_is(200)->json_has('/quiz_session')->tx->res->json;

        $mf_sc->discard_changes;
        is $mf_sc->status, 'inProgress', 'status is inProgress';
        is $mf_sc->completed_questionnaires_id, [7, 9], 'completed b0 and b1';

        $first_msg = $json->{quiz_session}{current_msgs}[0];
        $input_msg = $json->{quiz_session}{current_msgs}[-1];
        $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};

        like $first_msg->{content}, qr/Que bom que você não está sozinha/, 'campo display ok';
        is $input_msg->{type},      'text',                                'campo livre - pergunta campo livre';

        $json = $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $session_id,
                $field_ref => 'foo bar',
            }
        )->status_is(200)->json_has('/quiz_session')->tx->res->json;

        $mf_sc->discard_changes;
        is $mf_sc->completed_questionnaires_id, [7, 9, 10], 'completed b0, b1 and b2';
        is $mf_sc->status, 'inProgress', 'status is inProgress';

        $first_msg = $json->{quiz_session}{current_msgs}[0];
        $input_msg = $json->{quiz_session}{current_msgs}[-1];
        $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};

        like $first_msg->{content}, qr/teste mc/,      'teste de MC';
        is $input_msg->{type},      'multiplechoices', 'multiplechoices';

        $json = $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $session_id,
                $field_ref => '0,2',         # opção A e C
            }
        )->status_is(200)->json_has('/quiz_session')->tx->res->json;

        $first_msg = $json->{quiz_session}{current_msgs}[0];
        $input_msg = $json->{quiz_session}{current_msgs}[-1];
        $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};

        like $first_msg->{content}, qr/Até mais/, 'texto final';
        is $input_msg->{type},      'button',     'botao para finalizar';

        my $cliente_quiz_session = get_schema2->resultset('ClientesQuizSession')->find($session_id);
        my $responses            = from_json($cliente_quiz_session->responses);

        ok delete $responses->{start_time}, 'has start_time';

        is $responses, {
            b0_p0                => 'p0a',
            b1_p1                => 'Y',
            b2_primeira_e_ultima => 'foo bar',
            MC_X                 => '[0,2]',
            MC_X_json            => '["A","C"]',
          },
          'match expected responses';

        $json = $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $session_id,
                $field_ref => 'ok',
            }
        )->status_is(200)->json_has('/quiz_session')->tx->res->json;

        $mf_sc->discard_changes;
        is $mf_sc->completed_questionnaires_id,   [], 'back to empty';
        is $mf_sc->status,                        'completed', 'status is completed';
        is $mf_sc->current_clientes_quiz_session, undef,       'current_clientes_quiz_session is back to null';

        is $json->{quiz_session}{finished}, 1, 'finished=1';
        ok $json->{quiz_session}{end_screen}, 'has end_screen';

        # chama com o session (numerico) da not found
        $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $session_id,
            }
        )->status_is(400);

        $me_tarefas = $t->get_ok(
            '/me/tarefas',
            {'x-api-key' => $session},
            form => {modificado_apos => $epoch_start},
        )->status_is(200, 'busca todas as tarefas')->tx->res->json;

        $session_id = $me_tarefas->{mf_assistant}{quiz_session}{session_id};

        $json = $t->post_ok(
            '/me/quiz',
            {'x-api-key' => $session},
            form => {
                session_id => $session_id,
            }
        )->status_is(200)->json_has('/quiz_session')->tx->res->json;
        $first_msg = $json->{quiz_session}{current_msgs}[0];

        like $first_msg->{content}, qr/bem-vinda/, 'refazendo o questionario';

    };

};

sub get_user_mf_sc {
    my ($cliente_id) = @_;

    return get_schema2->resultset('ClienteMfSessionControl')->find({cliente_id => $cliente_id});
}

done_testing();

exit;
