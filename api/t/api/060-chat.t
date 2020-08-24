use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;
use Penhas::Test;
use Penhas::Minion::Tasks::SendSMS;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;
use DateTime;

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

my $nome_completo = 'test ponto apoio';

$t->get_ok('/pontos-de-apoio-dados-auxiliares')->status_is(200)->json_has('/categorias/0/label', 'has cat label')
  ->json_has('/projetos/0/label',    'has proj label')->json_has('/fields/0/code', 'field has code')
  ->json_has('/fields/0/max_length', 'field has max_length')->json_has('/fields/0/required', 'field has required');


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
            senha         => '123456',
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
            senha         => '123456',
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
            senha         => '123456',
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


my $skill1 = $schema2->resultset('Skill')->next;
my $skill2 = $schema2->resultset('Skill')->search({id => {'!=' => $skill1->id}})->next;

ok $skill1, 'skill1 is defined';
ok $skill2, 'skill2 is defined';

my $skills_in_order = join ', ', sort { $a cmp $b } $skill1->skill, $skill2->skill;

do {

    is $cliente->clientes_app_activity, undef, 'no clientes_app_activities';
    $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200, 'da um get pra marcar o clientes_app_activities');
    ok $cliente->clientes_app_activity, 'clientes_app_activities exists';

    test_instance->app->cliente_set_skill(user => {id => $cliente->id}, skills => [$skill1->id, $skill2->id]);

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
      )->status_is(200, 'listando usuarios')                                                #
      ->json_is('/rows/0/cliente_id', $cliente_id, 'id ok cli 1')                           #
      ->json_hasnt('/rows/1', '1 rows')                                                     #
      ->json_is('/has_more',      0,                'has more false')                       #
      ->json_is('/rows/0/skills', $skills_in_order, 'skills ok');

    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {name => 'a'},
      )->status_is(400, 'filtro por nome')                                                  #
      ->json_is('/error',  'form_error')                                                    #
      ->json_is('/field',  'name')                                                          #
      ->json_is('/reason', 'invalid_min_length');

    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session},
        form => {name => 'cliEnte c'},
      )->status_is(200, 'filtro por nome/apelido')                                          #
      ->json_is('/rows/0/apelido',    'cliente C',  'apelido ok')                           #
      ->json_is('/rows/0/cliente_id', $cliente_id3, 'id ok');

    db_transaction2 {
        $cliente2->update({genero => 'Homem', apelido => 'cliente bbb'});
        $t->get_ok(
            '/profile',
            {'x-api-key' => $session2},
            form => {cliente_id => $cliente_id},
        )->status_is(400, 'homen nao pode abrir profile');
    };

    $t->get_ok(
        '/profile',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
      )->status_is(200, 'abrir profile')    #
      ->json_is('/profile/apelido',    'cliente C',  'apelido ok')                       #
      ->json_is('/profile/cliente_id', $cliente_id3, 'id ok')                            #
      ->json_is('/profile/minibio',    '',           'minibio empty instead of null')    #
      ->json_is('/profile/skills',     '', 'sem skills')->json_is('/is_myself', '0', 'nao eh o mesmo usuario');

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
        '/me/chats/session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id},
    )->status_is(400, 'sem conversa de maluco');

    my $room1 = $t->post_ok(
        '/me/chats/session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id2},
      )->status_is(200, 'abre sala como cliente 1 com o cliente 2')    #
      ->json_like('/_test_only_id', qr/^\d+$/, 'id is defined')        #
      ->tx->res->json;

    my $room2 = $t->post_ok(
        '/me/chats/session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
    )->status_is(200, 'abre sala como cliente 1 com o cliente 3')->tx->res->json;
    isnt($room2->{_test_only_id}, $room1->{_test_only_id}, 'id is not the same room');

    my $room2_other_side = $t->post_ok(
        '/me/chats/session',
        {'x-api-key' => $session3},
        form => {cliente_id => $cliente_id},
      )->status_is(200, 'abre sala como cliente 3 com o cliente 1')    #
      ->json_is('/_test_only_id', $room2->{_test_only_id}, 'same room id');

    my $room2_same_room = $t->post_ok(
        '/me/chats/session',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
    )->status_is(200, 'abre sala como cliente 1 com o cliente 3 deve pegar a mesma sala')
      ->json_is('/_test_only_id', $room2->{_test_only_id}, 'is the same room as before')->tx->res->json;

    $t->get_ok(
        '/me/chats',
        {'x-api-key' => $session},
        form => {cliente_id => $cliente_id3},
      )->status_is(200, 'lista as conversas')    #
      ->json_is('/rows/0/other_apelido',      'cliente C')    #
      ->json_is('/rows/0/last_message_is_me', '1')            #
      ->json_is('/rows/0/other_activity',     'online')       #
      ->json_is('/rows/1/other_apelido',      'cliente B')    #
      ->json_is('/rows/1/last_message_is_me', '1')            #
      ->json_is('/rows/1/other_activity',     'online')       #
      ->json_is('/has_more',                  '0')            #
      ->json_is('/next_page',                 undef, 'tem next_page mesmo sendo undef');

};

done_testing();

exit;
