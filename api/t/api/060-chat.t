#!/usr/bin/perl
# HARNESS-CONFLICTS CHAT

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
AGAIN:
my $random_cpf2   = random_cpf();
my $random_email2 = 'email' . $random_cpf2 . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf2);
AGAIN:
my $random_cpf3   = random_cpf();
my $random_email3 = 'email' . $random_cpf3 . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf3);

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';
$ENV{SKIP_END_NEWS}            = '1';

my @other_fields = (
    raca        => 'branco',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

my $nome_completo = 'test chat';

get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf_hashed  => cpf_hash_with_salt($random_cpf),
        dt_nasc     => '1994-01-31',
        nome_hashed => cpf_hash_with_salt(uc $nome_completo),
        situacao    => '',
    }
);
get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf_hashed  => cpf_hash_with_salt($random_cpf2),
        dt_nasc     => '1994-01-31',
        nome_hashed => cpf_hash_with_salt(uc $nome_completo),
        situacao    => '',
    }
);
get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf_hashed  => cpf_hash_with_salt($random_cpf3),
        dt_nasc     => '1994-01-31',
        nome_hashed => cpf_hash_with_salt(uc $nome_completo),
        situacao    => '',
    }
);

my ($badge) = get_schema2->resultset('Badge')->search({id => -1})->all;
if (!$badge) {
    $badge = get_schema2->resultset('Badge')->create(
        {
            id          => -1,
            name        => 'test badge',
            description => 'test badge description',
            image_url   => 'test badge image',
            code        => 'test-badge',
        }
    );
}

my ($cliente_id,  $session,  $cliente);
my ($cliente_id2, $session2, $cliente2);
my ($cliente_id3, $session3, $cliente3);
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

subtest_buffered 'Cadastro2 com sucesso' => sub {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => $nome_completo,
            cpf           => $random_cpf2,
            email         => $random_email2,
            senha         => 'ARUKEAS SS3',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero  => 'Feminino',
            apelido => 'cliente B',

        },
    )->status_is(200)->tx->res->json;

    $cliente_id2 = $res->{_test_only_id};
    $session2    = $res->{session};
    $cliente2    = $schema2->resultset('Cliente')->find($cliente_id2);
};

subtest_buffered 'Cadastro2 com sucesso' => sub {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => $nome_completo,
            cpf           => $random_cpf3,
            email         => $random_email3,
            senha         => 'ARUKEAS SS1',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero  => 'Feminino',
            apelido => 'cliente C',

        },
    )->status_is(200)->tx->res->json;

    $cliente_id3 = $res->{_test_only_id};
    $session3    = $res->{session};
    $cliente3    = $schema2->resultset('Cliente')->find($cliente_id3);
};
on_scope_exit { user_cleanup(user_id => [$cliente_id, $cliente_id2, $cliente_id3,]); };


$t->get_ok('/filter-skills', {'x-api-key' => $session})->status_is(200);

db_transaction {

    my $skill1 = $schema2->resultset('Skill')->next;
    if (!$skill1) {
        $skill1 = $schema2->resultset('Skill')->create({skill => 'skill 1', status => 'published', sort => 1});
    }
    ok $skill1, 'skill 1 is defined';
    my $skill2 = $schema2->resultset('Skill')->search({id => {'!=' => $skill1->id}})->next;
    ok $skill2, 'skill 2 is defined';
    if (!$skill2) {
        $skill2 = $schema2->resultset('Skill')->create({skill => 'skill 2', status => 'published', sort => 2});
    }
    my $skill3 = $schema2->resultset('Skill')->search({id => {'not in' => [$skill1->id, $skill2->id]}})->next;
    if (!$skill3) {
        $skill3 = $schema2->resultset('Skill')->create({skill => 'skill 3', status => 'published', sort => 3});
    }
    ok $skill3, 'skill 3 is defined';

    my $skills_in_order = join ', ', sort { $a cmp $b } $skill1->skill, $skill2->skill;

    is $cliente->clientes_app_activity, undef, 'no clientes_app_activities';
    $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200, 'da um get pra marcar o clientes_app_activities');
    ok $cliente->clientes_app_activity, 'clientes_app_activities exists';

    $t->app->cliente_set_skill(user => {id => $cliente->id}, skills => [$skill1->id, $skill2->id]);

    $Penhas::Helpers::Chat::ForceFilterClientes = [$cliente_id, $cliente_id2, $cliente_id3];
    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session}
      )->status_is(200, 'listando usuarios')    #
      ->json_is('/rows/0/apelido',    'cliente A', 'nome ok')    #
      ->json_is('/rows/0/activity',   'online')                  #
      ->json_is('/rows/0/cliente_id', $cliente_id, 'id ok')      #
      ->json_hasnt('/rows/1', '1 row');                          #;

    $t->get_ok('/me', {'x-api-key' => $session2})->status_is(200, 'clientes_app_activities 2');
    $t->get_ok('/me', {'x-api-key' => $session3})->status_is(200, 'clientes_app_activities 3');

    # pra nao atrapalhar o resto dos testes
    $ENV{SUPPRESS_USER_ACTIVITY} = 1;

    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {rows => 2}
      )->status_is(200, 'listando usuarios')                     #
      ->json_is('/rows/0/cliente_id', $cliente_id3, 'id ok cli 3')    #
      ->json_is('/rows/1/cliente_id', $cliente_id2, 'id ok cli 2')    #
      ->json_hasnt('/rows/2', '2 rows')                               #
      ->json_has('/next_page', 'has next_page')                       #;
      ->json_is('/has_more', '1');                                    #;
    my $next_page = last_tx_json->{next_page};
    db_transaction2 {
        $cliente->update({genero => 'Homem'});
        $t->get_ok(
            '/search-users',
            {'x-api-key' => $session}
        )->status_is(400, 'homem nao pode listar')->json_is('/error', 'form_error');

        $t->get_ok(
            '/search-users',
            {'x-api-key' => $session2},
            form => {rows => 2, next_page => $next_page},
          )->status_is(200, 'listando usuarios')    #
          ->json_hasnt('/rows/0', 'nao tem ninguem pq homem nao deve aparecer na lista')    #
          ->json_is('/has_more', 0, 'has more false');
    };
    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {rows => 2, next_page => $next_page},
      )->status_is(200, 'listando usuarios')    #
      ->json_is('/rows/0/cliente_id', $cliente_id, 'id ok cli 1')        #
      ->json_hasnt('/rows/1', '1 rows')                                  #
      ->json_is('/has_more',      0,                'has more false')    #
      ->json_is('/rows/0/skills', $skills_in_order, 'skills ok');

    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {name => 'a'},
      )->status_is(400, 'filtro por nome')                               #
      ->json_is('/error',  'form_error')                                 #
      ->json_is('/field',  'name')                                       #
      ->json_is('/reason', 'invalid_min_length');

    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {name => 'cliEnte c'},
      )->status_is(200, 'filtro por nome/apelido')                       #
      ->json_is('/rows/0/apelido',    'cliente C',  'apelido ok')        #
      ->json_is('/rows/0/cliente_id', $cliente_id3, 'id ok');

    $t->app->cliente_set_skill(user => {id => $cliente_id2}, skills => [$skill1->id]);

    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {skills => join(',', $skill2->id, $skill1->id)}
      )->status_is(200, 'listando usuario com skills (OR)')              #
      ->json_is('/rows/0/cliente_id', $cliente_id2, 'first is last active user with skill1')    #
      ->json_is('/rows/1/cliente_id', $cliente_id,  'then myself')                              #
      ->json_hasnt('/rows/2', '2 rows only')                                                    #
      ->json_has('/next_page', undef, 'no next_page')                                           #;
      ->json_is('/has_more', '0');                                                              #;

    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {skills => $skill2->id}
      )->status_is(200, 'listando usuario com skills (OR)')                                     #
      ->json_is('/rows/0/cliente_id', $cliente_id, 'apenas o cliente 1 tem a skill2')           #
      ->json_hasnt('/rows/1', '1 row only')                                                     #
      ->json_has('/next_page', undef, 'no next_page')                                           #;
      ->json_is('/has_more', '0');                                                              #;

    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {skills => $skill3->id}
      )->status_is(200, 'listando usuario com skills (OR)')                                     #
      ->json_hasnt('/rows/0', 'no rows match skill 3')                                          #
      ->json_has('/next_page', undef, 'no next_page')                                           #;
      ->json_is('/has_more', '0');                                                              #;


    db_transaction2 {
        $cliente2->update({genero => 'Homem', apelido => 'cliente bbb'});
        $t->get_ok(
            '/profile',
            {'x-api-key' => $session2},
            form => {cliente_id => $cliente_id},
        )->status_is(400, 'homen nao pode abrir profile');
    };

    $badge->update({linked_cep_cidade => undef});
    $t->get_ok(
        '/profile',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
      )->status_is(200, 'abrir profile')    #
      ->json_is('/profile/apelido',    'cliente C',  'apelido ok')                       #
      ->json_is('/profile/cliente_id', $cliente_id3, 'id ok')                            #
      ->json_is('/profile/minibio',    '',           'minibio empty instead of null')    #
      ->json_is('/profile/badges',     [],           'no badges')                        #
      ->json_is('/profile/skills',     '', 'sem skills')->json_is('/is_myself', '0', 'nao eh o mesmo usuario');


    app->cliente_add_badge(user_obj => $cliente3, badge_id => $badge->id);

    $t->get_ok(
        '/profile',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
      )->status_is(200, 'abrir profile')                                                 #
      ->json_is('/profile/badges/0/code', 'test-badge', 'badge code');

    $cliente->update({minibio => 'abc foo', avatar_url => 'avatar.url'});
    $t->get_ok(
        '/profile',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id},
      )->status_is(200, 'abrir profile')                                                 #
      ->json_is('/profile/apelido',    'cliente A',      'apelido ok')                   #
      ->json_is('/profile/cliente_id', $cliente_id,      'id ok')                        #
      ->json_is('/profile/minibio',    'abc foo',        'minibio ok')                   #
      ->json_is('/profile/avatar_url', 'avatar.url',     'avatar ok')                    #
      ->json_is('/profile/skills',     $skills_in_order, 'skills match')                 #
      ->json_is('/is_myself',          '1',              'sou o mesmo usuario');


    $t->post_ok(
        '/me/chats-session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id},
    )->status_is(400, 'sem conversa de maluco')->json_is('/error', 'cannot_message_yourself');

    my $room1 = $t->post_ok(
        '/me/chats-session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id2},
      )->status_is(200, 'abre sala como cliente 1 com o cliente 2')    #
      ->json_like('/_test_only_id', qr/^\d+$/, 'id is defined')        #
      ->tx->res->json;

    my $room2 = $t->post_ok(
        '/me/chats-session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
    )->status_is(200, 'abre sala como cliente 1 com o cliente 3')->tx->res->json;
    isnt($room2->{_test_only_id}, $room1->{_test_only_id}, 'id is not the same room');

    my $room2_other_side = $t->post_ok(
        '/me/chats-session',
        {'x-api-key' => $session3},
        form => {cliente_id => $cliente_id},
      )->status_is(200, 'abre sala como cliente 3 com o cliente 1')    #
      ->json_is('/_test_only_id', $room2->{_test_only_id}, 'same room id')->tx->res->json;

    my $room2_same_room = $t->post_ok(
        '/me/chats-session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
      )->status_is(200, 'abre sala como cliente 1 com o cliente 3 deve pegar a mesma sala')    #
      ->json_has('/chat_auth', 'tem chat_auth')                                                #
      ->json_is('/_test_only_id', $room2->{_test_only_id}, 'is the same room as before')->tx->res->json;

    $t->get_ok(
        '/me/chats',
        {'x-api-key' => $session},
      )->status_is(200, 'lista as conversas')                                                  #
          #->json_is('/rows/0/other_apelido',      'cliente C')                                     #
          #->json_is('/rows/0/last_message_is_me', '1')                                             #
          #->json_is('/rows/0/other_activity',     'online')                                        #
          #->json_is('/rows/1/other_apelido',      'cliente B')                                     #
          #->json_is('/rows/1/last_message_is_me', '1')                                             #
          #->json_is('/rows/1/other_activity',     'online')                                        #
          #->json_has('/rows/1/chat_auth', 'has chat_auth')                                         #
          #->json_has('/rows/0/chat_auth', 'has chat_auth')                                         #
      ->json_is('/has_more',  '0')    #
      ->json_is('/rows',      [],    'no list empty rooms')                #
      ->json_is('/next_page', undef, 'tem next_page mesmo sendo undef');

    $ENV{NOTIFICATIONS_ENABLED} = 1;
    my $hello_from_cli1 = (join '', ('hello from cliente 1! ') x 100) . rand . ' atenção にほんご';

    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $room2_same_room->{chat_auth},
            message   => $hello_from_cli1
        },
      )->status_is(200, 'mandando mensagem')    #
      ->json_has('/id', 'we got an id!');

    $t->get_ok(
        '/me/chats',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
      )->status_is(200, 'listar os chats')      #
      ->json_is('/rows/0/other_apelido',       'cliente C',  'apelido ok')    #
      ->json_is('/rows/0/other_badges/0/name', 'test badge', 'badge name')    #
      ->json_is('/support/other_badges',       []);


    &test_notifcations(other_id => $cliente_id3, cliente_id => $cliente_id);

    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $room2_same_room->{chat_auth},
            message   => '0'
        },
      )->status_is(200, 'mandando mensagem com valor 0')    #
      ->json_has('/id', 'we got an id!');

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $room2_same_room->{chat_auth},
        },
      )->status_is(200, 'listando mensagens')               #
      ->json_is('/messages/0/message',  '0',              'message is zero')    #
      ->json_is('/messages/1/message',  $hello_from_cli1, 'hello is there')     #
      ->json_is('/messages/0/is_me',    '1',              'is myself')          #
      ->json_is('/messages/1/is_me',    '1',              'is myself')          #
      ->json_is('/other/badges/0/name', 'test badge',     'badge name');


    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_same_room->{chat_auth},
        },
      )->status_is(400, 'nao pode listar msg usando o token de outro usuario')    #
      ->json_is('/error', 'chat_auth_invalid_user');


    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
        },
      )->status_is(200, 'listando mensagens')                                     #
      ->json_is('/messages/0/message', '0',              'message is zero')       #
      ->json_is('/messages/1/message', $hello_from_cli1, 'hello is there')        #
      ->json_is('/messages/0/is_me',   '0',              'is NOT myself')         #
      ->json_is('/messages/1/is_me',   '0',              'is NOT myself')         #
      ->json_is('/other/badges',       [],               'no badges')             #
      ->json_is('/other/activity',     'online')                                  #
      ->json_is('/has_more',           '0', 'nao tem mais msg');

    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
            message   => '0'
        },
      )->status_is(400, 'nao pode mandar msg do lado errado tbm')                 #
      ->json_is('/error', 'chat_auth_invalid_user');

    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
            message   => 'working'
        },
      )->status_is(200, 'mandando mensagem usuario 3')                            #
      ->json_has('/id', 'we got an id!');

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
            rows      => 2,
        },
      )->status_is(200, 'teste paginacao')                                        #
      ->json_is('/messages/0/message', 'working', 'last msg is the first')        #
      ->json_is('/messages/0/is_me',   '1',       'is me')                        #
      ->json_is('/messages/1/message', '0',       'other msg')                    #
      ->json_is('/messages/1/is_me',   '0',       'is not myself')                #
      ->json_is('/has_more',           '1',       'has more messages')            #
      ->json_has('/older', 'has older pagination')                                #
      ->json_has('/newer', 'has newer pagination');

    my $older = last_tx_json()->{older};
    my $newer = last_tx_json()->{newer};
    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth  => $room2_other_side->{chat_auth},
            pagination => $older,
        },
      )->status_is(200, 'teste paginacao')                                        #
      ->json_is('/messages/0/message', $hello_from_cli1, 'expected message')      #
      ->json_is('/messages/1',         undef,            'no older msg')          #
      ->json_is('/has_more',           '0',              'no more messages')      #
      ->json_hasnt('/older', 'no older pagination')                               #
      ->json_hasnt('/newer', 'no newer pagination');

    my $hey_long_msg = join ' ', ('hey!') x 100;
    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $room2->{chat_auth},
            message   => $hey_long_msg
        },
      )->status_is(200, 'mandando mensagem nova')                                 #
      ->json_has('/id', 'we got an id!');
    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $room2->{chat_auth},
            message   => 'me responde!'
        },
      )->status_is(200, 'mandando mensagem nova')                                 #
      ->json_has('/id', 'we got an id!');

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth  => $room2_other_side->{chat_auth},
            pagination => $newer,
        },
      )->status_is(200, 'teste paginacao (puxando novidades)')                    #
      ->json_is('/messages/0/message', 'me responde!', 'expected message')        #
      ->json_is('/messages/1/message', $hey_long_msg,  'expected message')        #
      ->json_is('/messages/2',         undef,          'no older msg')            #
      ->json_is('/has_more',           '0',            'no more messages')        #
      ->json_hasnt('/older', 'no older pagination')                               #
      ->json_has('/newer', 'newer pagination');
    $newer = last_tx_json()->{newer};
    ok $t->app->decode_jwt($newer)->{after}, 'after is definded';

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth  => $room2_other_side->{chat_auth},
            pagination => $newer,
        },
      )->status_is(200, 'teste paginacao (puxando novidades, mas nao tem mais)')    #
      ->json_is('/messages', [],  'no msg')                                         #
      ->json_is('/has_more', '0', 'no more messages')                               #
      ->json_hasnt('/older', 'no older pagination')                                 #
      ->json_has('/newer', 'newer pagination');
    $newer = last_tx_json()->{newer};
    ok $t->app->decode_jwt($newer)->{after}, 'after is definded';

    # BLOCKS
    $t->post_ok(
        '/me/manage-blocks',
        {'x-api-key' => $session2},
        form => {
            cliente_id => $cliente_id2,
            block      => 0,
        }
      )->status_is(400, 'cannot block yourself')    #
      ->json_is('/error', 'cannot_block_yourself');

    $t->post_ok(
        '/me/manage-blocks',
        {'x-api-key' => $session2},
        form => {
            cliente_id => $cliente_id2,
            block      => '',
        }
      )->status_is(400, 'block must be 1 or 0')     #
      ->json_is('/error',  'form_error')            #
      ->json_is('/field',  'block')                 #
      ->json_is('/reason', 'is_required');

    # cliente 3 bloqueia o cliente 1
    $t->post_ok(
        '/me/manage-blocks',
        {'x-api-key' => $session3},
        form => {
            cliente_id => $cliente_id,
            block      => '1',
        }
    )->status_is(204, 'block updated');

    # ainda possível abrir a sala
    my $room2_same_room_after_block = $t->post_ok(
        '/me/chats-session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
      )->status_is(200, 'abre sala como cliente 1 com o cliente 3 deve pegar a mesma sala')    #
      ->json_has('/chat_auth', 'tem chat_auth')                                                #
      ->json_is('/_test_only_id', $room2->{_test_only_id}, 'is the same room as before')->tx->res->json;

    # cliente 1 pro cliente 3
    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session},
        form => {
            chat_auth => $room2_same_room_after_block->{chat_auth},
            message   => 'nan demo nai'
        },
      )->status_is(400, 'nao pode mandar msg pq ta blocked')                                   #
      ->json_is('/error', 'blocked');

    # cliente 3 pro cliente 1 tambem nao deve mandar, até desbloquear
    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
            message   => 'nan demo nai'
        },
      )->status_is(400, 'nao pode mandar msg pq bloqueou o outro')                             #
      ->json_is('/error', 'remove_block_to_send_message');

    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
        },
      )->status_is(200, 'vendo historico')                                                     #
      ->json_is('/meta/can_send_message', 0, 'nao pq eu dei block')                            #
      ->json_is('/meta/did_blocked',      1, 'está blocked')                                   #
      ->json_is('/meta/is_blockable',     1, 'pq o chat é entre pessoas')
      ->json_has('/meta/last_msg_etag', 'tem last_msg_etag');
    my $last_etag = last_tx_json->{meta}{last_msg_etag};

    $t->post_ok(
        '/me/manage-blocks',
        {'x-api-key' => $session3},
        form => {
            cliente_id => $cliente_id,
            block      => '0',
        }
    )->status_is(204, 'block updated (unblock)');

    my $random_message = 'latest message' . rand;
    $t->post_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
            message   => $random_message
        },
      )->status_is(200, 'pode mandar novamente')    #
      ->json_is('/prev_last_msg_etag', $last_etag, 'ultima etag bate com a listagem')
      ->json_has('/last_msg_etag', 'tem last_msg_etag');
    my $really_last_msg = last_tx_json->{last_msg_etag};
    $t->get_ok(
        '/me/chats-messages',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
        },
      )->status_is(200, 'vendo historico')          #
      ->json_is('/meta/can_send_message', 1, 'sim pq eu dei block')         #
      ->json_is('/meta/did_blocked',      0, 'não está blocked')            #
      ->json_is('/meta/is_blockable',     1, 'pq o chat é entre pessoas')
      ->json_unlike('/meta/last_msg_etag', qr/$last_etag/, 'etag mudou pq teve nova msg')
      ->json_is('/meta/last_msg_etag', $really_last_msg, 'ultima msg');

    $t->post_ok(
        '/me/chats-session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3, prefetch => 1},
      )->status_is(200, 'abrindo a sala e puxando as ultimas msg sozinho')    #
      ->json_has('/chat_auth',     'tem chat_auth')                           #
      ->json_has('/prefetch/meta', 'tem prefetch/meta')                       #
      ->json_is('/prefetch/messages/0/message', $random_message,         'ultima msg ok')
      ->json_is('/prefetch/messages/0/is_me',   0,                       'ultima msg eh do cliente 3')
      ->json_is('/_test_only_id',               $room2->{_test_only_id}, 'is the same room as before');


    $t->delete_ok(
        '/me/chats-session',
        {'x-api-key' => $session3},
        form => {
            chat_auth => $room2_other_side->{chat_auth},
        }
    )->status_is(204);

    $t->post_ok(
        '/me/chats-session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3, prefetch => 1},
      )->status_is(200, 'abrindo a sala vai abrir uma nova pq foi removida')    #
      ->json_has('/chat_auth',     'tem chat_auth')                             #
      ->json_has('/prefetch/meta', 'tem prefetch/meta')                         #
      ->json_is('/prefetch/messages', [], 'sem msgs')
      ->json_unlike('/_test_only_id', qr/${\$room2->{_test_only_id}}/, 'is NOT the same room as before');

};

done_testing();

exit;

sub test_notifcations {
    my (%opts)     = @_;
    my $other_id   = $opts{other_id};
    my $cliente_id = $opts{cliente_id};

    my $rs = get_schema2->resultset('ChatClientesNotification')->search({cliente_id => $other_id});

    is $rs->count, 1, 'one pending notification to other';

    my $row = $rs->next;

    $ENV{MAINTENANCE_SECRET}  = 'SECRET';
    $ENV{MAINTENANCE_USER_ID} = $other_id;
    my $user = get_schema2->resultset('Cliente')->find($other_id);

    is $row->notification_created, '0', 'not notified yet';
    $t->get_ok('/maintenance/tick-notifications', form => {secret => $ENV{MAINTENANCE_SECRET}})->status_is(200);

    is $row->discard_changes->notification_created, '0', 'still not notified';

    $row->update({messaged_at => \"NOW() + INTERVAL '-6 MINUTE'"});

    is $ENV{LAST_CHAT_JOB_ID}, undef, 'no LAST_CHAT_JOB_ID yet';
    $t->get_ok('/maintenance/tick-notifications', form => {secret => $ENV{MAINTENANCE_SECRET}})->status_is(200);

    is $row->discard_changes->notification_created, '1', 'now is notified';
    ok defined $ENV{LAST_CHAT_JOB_ID}, 'LAST_CHAT_JOB_ID is defined';

    my $job = Minion::Job->new(
        id     => fake_int(1, 99)->(),
        minion => $t->app->minion,
        task   => 'testmocked',
        notes  => {hello => 'mock'}
    );
    is $user->notification_logs->count, 0, 'no logs';
    trace_popall;
    ok(
        Penhas::Minion::Tasks::NewNotification::new_notification(
            $job, test_get_minion_args_job($ENV{LAST_CHAT_JOB_ID})
        ),
        'job'
    );
    is $user->notification_logs->count, 1, 'inserted';
    is trace_popall, 'minion:new_notification,new_message,NOTIFY_CHAT_NEW_MESSAGES,1', 'expected code path';

    $row->update({messaged_at => \"NOW() + INTERVAL '-2 DAY'"});

    $t->get_ok('/maintenance/tick-notifications', form => {secret => $ENV{MAINTENANCE_SECRET}})->status_is(200);
    is $rs->count, '0', 'deleted because too old';


    $cliente->cliente_modo_anonimo_toggle(active => 1);
    trace_popall;
    $t->get_ok(
        ('/me/notifications'),
        {'x-api-key' => $session3},
    )->status_is(200, 'notifications with chat');
    is trace_popall, 'anon_user:cliente A,expand_screen=' . $cliente_id, 'right code';

    $cliente->cliente_modo_anonimo_toggle(active => 0);

}
