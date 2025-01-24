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
use Penhas::Utils qw/tt_test_condition tt_render/;
my $schema2 = $t->app->schema2;

my $now_datetime = DateTime->now()->datetime(' ');

AGAIN:
my $random_cpf   = random_cpf();
my $random_email = 'email' . $random_cpf . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf);

my $random_code = '_' . random_cpf();

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';
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


    is tt_test_condition("is_json_member('a', XXX)", {}), 0, 'is_json_member return false when reference do not exists';
    is tt_test_condition("is_json_member('a', XXX)", {XXX => to_json(["a"])}), 1,
      'is_json_member return true when item exists';
    is tt_test_condition("is_json_member('b', XXX)", {XXX => to_json(["a"])}), 0,
      'is_json_member return false when item is not found';

    is tt_render("[% json_array_to_string(ref, 'me', 'skip') %]", {ref => to_json(["you", "it", "skip"])}),
      'you, it e me',
      'json_array_to_string is working';

    $ENV{ENABLE_MANUAL_FUGA} = 0;
    my $me_perfil = $t->get_ok(
        '/me',
        {'x-api-key' => $session},
        form => {},
    )->status_is(200, '')->tx->res->json;
    my ($cnt) = grep { $_->{code} eq 'mf' } @{$me_perfil->{modules}};
    is $cnt, undef, 'no mf module';

    $ENV{ENABLE_MANUAL_FUGA} = 1;
    $me_perfil = $t->get_ok(
        '/me',
        {'x-api-key' => $session},
        form => {},
    )->status_is(200, '')->tx->res->json;

    my ($mf) = grep { $_->{code} eq 'mf' } @{$me_perfil->{modules}};
    is $mf->{meta}{max_checkbox_contato}, 3, 'max_checkbox_contato=3';


    my $mf_tarefa_rs         = $schema2->resultset('MfTarefa');
    my $mf_cliente_tarefa_rs = $schema2->resultset('MfClienteTarefa');

    my $tarefa_1_sistema = $mf_tarefa_rs->create(
        {
            titulo         => 'titulo 1',
            descricao      => 'descricao 1',
            tipo           => 'checkbox',
            codigo         => $random_code,
            eh_customizada => 'false',
            agrupador      => 'nope'
        }
    );

    my $epoch_start = time() - 20000;
    $t->get_ok(
        '/me/tarefas',
        {'x-api-key' => $session},
        form => {modificado_apos => $epoch_start},
      )->status_is(200, 'busca todas as tarefas')    #
      ->json_is('/tarefas', [], 'ainda sem nenhuma tarefa');


    my $mfc1 = $mf_cliente_tarefa_rs->create(
        {
            mf_tarefa_id   => $tarefa_1_sistema->id,
            cliente_id     => $cliente_id,
            checkbox_feito => 'false',
            atualizado_em  => \['to_timestamp(?)', $epoch_start + 1],
        }
    );

    $t->get_ok(
        '/me/tarefas',
        {'x-api-key' => $session},
        form => {modificado_apos => $epoch_start},
      )->status_is(200, 'busca todas as tarefas')    #
      ->json_is('/tarefas/0/id',             $mfc1->id, 'tarefa retornada')    #
      ->json_is('/tarefas/0/titulo',         $tarefa_1_sistema->titulo)        #
      ->json_is('/tarefas/0/descricao',      $tarefa_1_sistema->descricao)     #
      ->json_is('/tarefas/0/checkbox_feito', '0')                              #
      ->json_is('/tarefas/0/eh_customizada', '0')                              #
      ->json_is('/tarefas/0/agrupador',      'nope')                           #
      ->json_is('/tarefas/0/tipo',           $tarefa_1_sistema->tipo)          #
      ->json_is('/tarefas/0/atualizado_em',  $epoch_start + 1)                 #
      ;

    $t->post_ok(
        '/me/tarefas/sync',
        {'x-api-key' => $session},
        form => {
            id             => $mfc1->id,
            checkbox_feito => 1,
        },
    )->status_is(204, 'sync de task');

    $t->get_ok(
        '/me/tarefas',
        {'x-api-key' => $session},
        form => {modificado_apos => $epoch_start},
    )->status_is(200, 'busca todas as tarefas desde um X momento')->json_is('/tarefas/0/checkbox_feito', '1');

    $t->post_ok(
        '/me/tarefas/sync',
        {'x-api-key' => $session},
        form => {
            id             => $mfc1->id,
            checkbox_feito => 0,
        },
    )->status_is(204, 'sync de task como não feito');

    $t->get_ok(
        '/me/tarefas',
        {'x-api-key' => $session},
        form => {modificado_apos => $epoch_start},
    )->status_is(200, 'busca todas as tarefas')->json_is('/tarefas/0/checkbox_feito', '0');

    $t->post_ok(
        '/me/tarefas/batch',
        {'x-api-key' => $session},
        json => [
            {
                id     => $mfc1->id,
                remove => 1,
            }
        ],
    )->status_is(200, 'batch de removido com sucesso');

    $t->get_ok(
        '/me/tarefas',
        {'x-api-key' => $session},
        form => {modificado_apos => $epoch_start},
      )->status_is(200, 'busca todas as tarefas')    #
      ->json_is('/tarefas',           [])            #
      ->json_is('/tarefas_removidas', [$mfc1->id]);


    my $json = $t->post_ok(
        '/me/tarefas/nova',
        {'x-api-key' => $session},
        form => {
            titulo           => 'hello',
            descricao        => 'world',
            agrupador        => 'hey',
            campo_livre      => '',                                          # pode enviar vazio
            checkbox_contato => '1',
            token            => $Penhas::Helpers::Cliente::NEW_TASK_TOKEN,
            modificado_apos  => $epoch_start,
        },
      )->status_is(200, 'adicionada com sucesso')    #
      ->json_has('/id')                              #
      ->json_has('/message', 'hello')->tx->res->json;
    my $tarefa_criada_id = $json->{id};

    $t->post_ok(
        '/me/tarefas/batch',
        {'x-api-key' => $session},
        json => [
            {
                id             => $tarefa_criada_id,
                campo_livre    => {hey => 1, deep => [1, "yes", {}]},
                checkbox_feito => 0,
            },
            {
                id             => $tarefa_criada_id,
                campo_livre    => '{}',
                checkbox_feito => 0,
            }
        ],
    )->status_is(200, 'sync em batch aceita json como objeto ou string');

    $t->post_ok(
        '/me/tarefas/batch',
        {'x-api-key' => $session},
        json => [
            {
                id             => $tarefa_criada_id,
                campo_livre    => '{}',
                checkbox_feito => 0,
            },
            {
                id             => $tarefa_criada_id,
                campo_livre    => 'ABC',
                checkbox_feito => 0,
            }
        ],
    )->status_is(400, 'sync com erro em batch recusa tudo');

    $t->post_ok(
        '/me/tarefas/batch',
        {'x-api-key' => $session},
        json => [
            {
                id             => $tarefa_criada_id,
                campo_livre    => {},
                checkbox_feito => 0,
            }
        ],
    )->status_is(200, 'sync em batch aceita json livre mesmo se for hash vazio');

    $t->get_ok(
        '/me/tarefas',
        {'x-api-key' => $session},
        form => {modificado_apos => $epoch_start},
      )->status_is(200, 'busca todas as tarefas')    #
      ->json_is('/tarefas/0/campo_livre', {})                    #
      ->json_is('/tarefas/0/tipo',        'checkbox_contato');

    $t->post_ok(
        '/me/tarefas/sync',
        {'x-api-key' => $session},
        form => {
            id             => $tarefa_criada_id,
            campo_livre    => '["abc", {"why": false}]',
            checkbox_feito => 1,
        },
    )->status_is(204, 'sync com sucesso');

    $t->get_ok(
        '/me/tarefas',
        {'x-api-key' => $session},
        form => {modificado_apos => $epoch_start},
      )->status_is(200, 'busca todas as tarefas')    #
      ->json_is('/tarefas/0/checkbox_feito', '1')                              #
      ->json_is('/tarefas/0/campo_livre',    ["abc", {why => JSON::false}]);


    # refazendo o "quiz B5"
    $ENV{MF_REDO_ADDR_QUESTIONNAIRE_ID} = 19;
    $schema2->resultset('MfQuestionnaireRemoveTarefa')->search({questionnaire_id => 20})->delete();
    $schema2->resultset('MfQuestionnaireRemoveTarefa')->create(
        {
            questionnaire_id => 20,
            codigo_tarefa    => $tarefa_1_sistema->codigo
        }
    );
    app->cliente_mf_add_tarefa_por_codigo(codigos => [$tarefa_1_sistema->codigo], user_obj => $cliente);

    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {session_id => $cliente->mf_redo_addr_session_id()},
      )->status_is(200, 'chamada com sucesso')    #
      ->tx->res->json;

    my $first_msg  = $json->{quiz_session}{current_msgs}[0];
    my $input_msg  = $json->{quiz_session}{current_msgs}[-1];
    my $session_id = $json->{quiz_session}{session_id};
    my $field_ref  = $json->{quiz_session}{current_msgs}[-1]{ref};

    my $session_id = $json->{quiz_session}{session_id};

    like $first_msg->{content}, "Você deseja refazer? (refazer)", "pergunta";

    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $session_id,
            $field_ref => 'N'

        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg  = $json->{quiz_session}{current_msgs}[0];
    $input_msg  = $json->{quiz_session}{current_msgs}[-1];
    $session_id = $json->{quiz_session}{session_id};
    $field_ref  = $json->{quiz_session}{current_msgs}[-1]{ref};

    ok $session_id, 'has session';

    use DDP;
    p $json;


    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {session_id => $cliente->mf_redo_addr_session_id()},
      )->status_is(200, 'chamada com sucesso')    #
      ->tx->res->json;
use DDP; p $json;
    my $new_session_id = $json->{quiz_session}{session_id};
    ok $new_session_id > $session_id, 'has newer session id';

    use DDP;
    p $json;

};

done_testing();

exit;
