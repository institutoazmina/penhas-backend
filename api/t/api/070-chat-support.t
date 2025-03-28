#!/usr/bin/perl
# HARNESS-CONFLICTS CHAT
use Mojo::Base -strict;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;
use Penhas::Test;
use Penhas::Minion::Tasks::SendSMS;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;
use DateTime;
use utf8;

BEGIN {
    plan skip_all => 'Faltando configurar TEST_DIRECTUS_PASSWORD' unless $ENV{TEST_DIRECTUS_PASSWORD};
};
my $schema2 = $t->app->schema2;

my $now_datetime = DateTime->now()->datetime(' ');

AGAIN:
my $random_cpf   = random_cpf();
my $random_email = 'email' . $random_cpf . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf);

my $admin_email = 'tests.automatic@example.com';
my $password    = $ENV{TEST_DIRECTUS_PASSWORD} || 'k8Mw9(wj3H';
do {
    # ID do role de test
    my $role_id = '8bad4430-dd52-440a-864d-f31bc8654f2d';
    my $admin   = $schema2->resultset('DirectusUser')->search(
        {
            status => 'active',
            email  => $admin_email
        }
    )->next;

    ok $admin, 'usuario directus de teste encontrado';
    is $admin->role, $role_id, 'role está correto';
    ok $admin->check_password($password), 'password está correta';

    $t->get_ok(
        '/admin/users',
    )->status_is(302, 'nao ta logado, 302, sem cookies');

    $ENV{ADMIN_ALLOWED_ROLE_IDS} = '';
    $t->post_ok(
        '/admin/login',
        form => {
            email => $admin_email,
            senha => $password,
        },
    )->status_is(400)->json_is('/error', 'wrongpassword');

    $ENV{ADMIN_ALLOWED_ROLE_IDS} = $role_id;
    $t->post_ok(
        '/admin/login',
        form => {
            email => $admin_email,
            senha => $password,
        },
    )->status_is(200)->json_is('/ok', '1', 'login was ok');

    $t->get_ok(
        '/admin',
    )->status_is(200, 'ta logado, pode usar');

    $t->get_ok(
        '/admin/logout',
    )->status_is(200)->json_is('/ok', '1', 'logout was ok');

    $t->get_ok(
        '/admin',
    )->status_is(302, 'nao ta logado, 302');

};

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';
$ENV{SKIP_END_NEWS}            = '1';

my @other_fields = (
    raca        => 'branco',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

my $nome_completo = 'test chat suporte';

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
            apelido       => 'suporte A',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'WQ534565^',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero      => rand() > 0.5 ? 'Feminino' : 'Masculino',
            nome_social => 'foo bar',
        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    $session    = $res->{session};
    $cliente    = $schema2->resultset('Cliente')->find($cliente_id);
};

$Penhas::Helpers::Chat::ForceFilterClientes = [$cliente_id];
on_scope_exit { user_cleanup(user_id => [$cliente_id,]); };

do {

    $t->get_ok(
        '/me/chats',
        {'x-api-key' => $session},
      )->status_is(200, 'lista as conversas')    #
      ->json_is('/support/chat_auth', $cliente->support_chat_auth(), 'support_chat_auth() match expected');

    # pra nao atrapalhar o resto dos testes
    $ENV{SUPPRESS_USER_ACTIVITY} = 1;

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $cliente->support_chat_auth(),
        },
      )->status_is(200, 'puxando mensagens com o suporte')    #
      ->json_is('/meta/can_send_message', 1, 'sim')                           #
      ->json_is('/meta/did_blocked',      0, 'não está blocked')              #
      ->json_is('/meta/is_blockable',     0, 'nao pq o chat é o suporte')     #
      ->json_has('/meta/last_msg_etag', 'tem os mesmos campos que o chat')    #
      ->json_is('/meta/is_blockable', 0, 'nao pq o chat é o suporte')         #
      ->json_like('/other/activity', qr/48h/, 'tem texto do activity');
    my $newer = last_tx_json()->{newer};

    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $cliente->support_chat_auth(),
            message   => '0'
        },
      )->status_is(200, 'mandando mensagem com valor 0')                      #
      ->json_has('/id', 'we got an id!');

    $t->post_ok(
        '/admin/login',
        form => {
            email => $admin_email,
            senha => $password,
        },
    )->status_is(200)->json_is('/ok', '1', 'login was ok');

    $t->get_ok(
        '/admin/users',
        form => {cliente_id => $cliente_id}
      )->status_is(200, 'filtro do usuario')    #
      ->json_is('/rows/0/nome_completo', $nome_completo, 'nome ok')         #
      ->json_is('/rows/0/id',            $cliente_id,    'id ok')           #
      ->json_is('/rows/1',               undef,          'only one row');

    my $reply_msg = 'reply from support' . rand;
    $t->post_ok(
        '/admin/send-message',
        form => {
            cliente_id => $cliente_id,
            message    => $reply_msg,
        }
    )->status_is(
        200,
        'respondendo um cliente'
    );

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth  => $cliente->support_chat_auth(),
            pagination => $newer
        },
      )->status_is(200, 'puxando mensagens com o suporte')    #
      ->json_is('/messages/0/is_me',   0,          'eh o suporte')        #
      ->json_is('/messages/1/is_me',   1,          'sou eu')              #
      ->json_is('/messages/0/message', $reply_msg, 'reply msg ok')        #
      ->json_is('/messages/1/message', '0',        'message com zero')    #
      ->json_has('/newer', 'tem newer');

    $newer = last_tx_json()->{newer};

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth  => $cliente->support_chat_auth(),
            pagination => $newer
        },
      )->status_is(200, 'puxando mensagens com o suporte')                #
      ->json_is('/messages', [], 'nao ha msgs novas')                     #
      ->json_has('/newer', 'ainda tem newer');

    for my $i (1 .. 3) {
        $t->post_ok(
            '/me/chats-messages',
            {'x-api-key' => $session},
            form => {
                chat_auth => $cliente->support_chat_auth(),
                message   => "Num $i"
            },
          )->status_is(200, "mandando mensagem com valor $i")    #
          ->json_has('/id', 'we got an id!');
    }

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth  => $cliente->support_chat_auth(),
            pagination => $newer,
            rows       => 2,
        },
      )->status_is(200, 'puxando duas novas mensagens')    #
      ->json_is('/messages/0/message', 'Num 3', 'msg=3')   #
      ->json_is('/messages/1/message', 'Num 2', 'msg=2')   #
      ->json_has('/newer', 'ainda vem newer')              #
      ->json_has('/older', 'ainda tem older')              #
      ->json_is('/has_more', 1, 'has_more true');

    my $older = last_tx_json()->{older};
    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth  => $cliente->support_chat_auth(),
            pagination => $older,
            rows       => 2,
        },
      )->status_is(200, 'puxando duas novas mensagens')    #
      ->json_is('/messages/0/message', 'Num 1',    'msg=1')              #
      ->json_is('/messages/1/message', $reply_msg, 'msg do suporte')     #
      ->json_hasnt('/newer', 'nao vem newer pq ta pagiando pra tras')    #
      ->json_has('/older', 'ainda tem older')                            #
      ->json_is('/has_more', 1, 'has_more true');
    $older = last_tx_json()->{older};
    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth  => $cliente->support_chat_auth(),
            pagination => $older,
            rows       => 2,
        },
      )->status_is(200, 'puxando athe o has_more false')                 #
      ->json_is('/messages/0/message', '0', 'msg inicial')               #
      ->json_hasnt('/newer', 'nao vem newer pq ta pagiando pra tras')    #
      ->json_hasnt('/older', 'ainda tem older pq acabou a pagina')       #
      ->json_is('/has_more', 0, 'has_more false');
    my $current_date = DateTime->now->ymd('-');
    $t->get_ok(
        '/admin/user-messages',
        form => {
            cliente_id => $cliente_id,
        }
      )->status_is(200, 'lista de mensagens')                            #
      ->json_is('/messages/0/message', 'Num 3')                          #
      ->json_is('/messages/1/message', 'Num 2')                          #
      ->json_is('/messages/2/message', 'Num 1')                          #
      ->json_is('/messages/2/is_me',   '0', 'nao eh o admin')            #
      ->json_is('/messages/3/message', $reply_msg)                       #
      ->json_is('/messages/3/is_me',   1, 'sou eu, o admin')             #
      ->json_like('/other/activity', qr/$current_date/, 'vem o horario');

    $t->delete_ok(
        '/me/chats-session',
        {'x-api-key' => $session},
        form => {
            chat_auth => $cliente->support_chat_auth(),
        }
    )->status_is(204);

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $cliente->support_chat_auth(),
        },
      )->status_is(200, 'mensagens limpas')    #
      ->json_is('/messages', [], 'sem msg');

};


done_testing();

exit;
