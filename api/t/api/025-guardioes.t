use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;
use Penhas::Minion::Tasks::SendSMS;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;

my $schema2 = $t->app->schema2;

AGAIN:
my $random_cpf   = random_cpf();
my $random_email = 'email' . $random_cpf . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf);

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';
$ENV{SKIP_END_NEWS}            = '1';

my @other_fields = (
    raca        => 'branco',
    apelido     => 'guardioes',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

my $nome_completo = 'test name guards';

get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf_hashed  => cpf_hash_with_salt($random_cpf),
        dt_nasc     => '1994-01-31',
        nome_hashed => cpf_hash_with_salt(uc $nome_completo),
        situacao    => '',
    }
);

my ($cliente_id, $session);
subtest_buffered 'Cadastro com sucesso' => sub {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => $nome_completo,
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '123456',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero => 'Feminino',

        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    $session    = $res->{session};
};

on_scope_exit { user_cleanup(user_id => $cliente_id); };

do {
    $ENV{GUARDS_ALLOWED_COUNTRY_CODES} = ',55,';

    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            celular => '+1 484 2918 467',
        }
    )->status_is(400)->json_is('/error', 'contry_not_allowed', 'testando bloqueio de paises');

    $ENV{GUARDS_ALLOWED_COUNTRY_CODES} = '';
    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            celular => '11 81144666',
        }
    )->status_is(400)->json_is('/error', 'parser_error', 'numero nao existe no brasil')->json_is('/field', 'celular')
      ->json_is('/reason', 'invalid');

    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            celular => '11 31144666',
        }
    )->status_is(400)->json_is('/error', 'number_is_not_mobile', 'numero nao eh celular')
      ->json_is('/field', 'celular')->json_is('/reason', 'invalid');


    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            celular => '+14842918467',
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '+1 484-291-8467')
      ->json_is('/data/nome',        'test nome')->json_is('/data/is_pending', '1')->json_is('/data/is_expired', '0')
      ->json_is('/data/is_accepted', '0')->json_like('/message', qr/Enviamos um SMS/);

    trace_popall;
    my $job = Minion::Job->new(
        id     => fake_int(1, 99)->(),
        minion => $t->app->minion,
        task   => 'testmocked',
        notes  => {hello => 'mock'}
    );
    ok(Penhas::Minion::Tasks::SendSMS::send_sms($job, test_get_minion_args_job(0)), 'send sms');
    do {
        my $text = trace_popall;
        like $text, qr/minion:send_sms,\+14842918467,SentSmsLog,/, 'logs looks ok';
        my ($log_id) = $text =~ /SentSmsLog,(\d+),?/;

        ok(my $logrow = $schema2->resultset('SentSmsLog')->find($log_id), 'log row found');
        is $logrow->phonenumber, '+14842918467', 'log number ok';
        $logrow->delete;
    };

    my $numero_brazil = '11 912341234';
    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'portugues',
            celular => "021 $numero_brazil",
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 91234-1234')
      ->json_is('/data/nome',        'portugues')->json_is('/data/is_pending', '1')->json_is('/data/is_expired', '0')
      ->json_is('/data/is_accepted', '0')->json_like('/message', qr/Enviamos um SMS/);

    ok(my $id = $t->tx->res->json->{data}{id}, 'has id');

    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'portugues',
            celular => "+55$numero_brazil",
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 91234-1234')
      ->json_like('/message', qr/convite aguardando/);
    my $row_to_be_removed;
    do {
        ok(my $id2 = $t->tx->res->json->{data}{id}, 'has id');
        is $id, $id2, 'same invite';

        $t->put_ok(
            join('', '/me/guardioes/', $id2),
            {'x-api-key' => $session},
            form => {nome => 'imasuguni'}
        )->status_is(200, 'edit name');

        ok($row_to_be_removed = $schema2->resultset('ClientesGuardio')->find($id2), 'row found');
        is $row_to_be_removed->nome, 'imasuguni', 'name updated';

        $t->delete_ok(
            join('', '/me/guardioes/', $id),
            {'x-api-key' => $session}
        )->status_is(204);

        $t->put_ok(
            join('', '/me/guardioes/', $id),
            {'x-api-key' => $session},
            form => {nome => 'cannot update'}
        )->status_is(404, 'not found after delete');
        $row_to_be_removed->discard_changes;
        is $row_to_be_removed->status, 'removed_by_user', '$row_to_be_removed is removed';
        ok $row_to_be_removed->deleted_at, 'has deleted_at';

        $t->post_ok(
            '/me/guardioes',
            {'x-api-key' => $session},
            form => {
                nome    => 'novo nao deve enviar sms',
                celular => $numero_brazil,
            }
        )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 91234-1234')
          ->json_like('/message', qr/reativado/);

        $row_to_be_removed->discard_changes;
        is $row_to_be_removed->status,     'pending',                  'pending again';
        is $row_to_be_removed->deleted_at, undef,                      'deleted_at null';
        is $row_to_be_removed->nome,       'novo nao deve enviar sms', 'nome updated';

        # atualiza a data que ele deve vencer:
        $row_to_be_removed->update(
            {
                created_at => \'date_sub(now(), interval 30 day)',
                expires_at => \'date_sub(now(), interval 1 second)',
                nome       => 'Expiraldo Silva'
            }
        );
    };

    # testa limpeza da cod de operadora
    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'portugues',
            celular => '021 11 943214321',
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 94321-4321')
      ->json_like('/message', qr/Enviamos um SMS/);
    ok(my $id3  = $t->tx->res->json->{data}{id},                      'has id');
    ok(my $row3 = $schema2->resultset('ClientesGuardio')->find($id3), 'row found');
    $row3->update({created_at => \'date_sub(now(), interval 10 day)'});

    # testa GET
    $t->get_ok(
        join('', '/me/guardioes'),
        {'x-api-key' => $session}
    )->status_is(200)->json_is('/guards/0/rows', [], 'nothing is accepted')
      ->json_is('/guards/0/meta/layout',    'accepted',             'first row layout is accepted')
      ->json_is('/guards/1/meta/layout',    'pending',              'second row layout is pending')
      ->json_is('/guards/1/rows/0/celular', '+1 484-291-8467',      'celular ok')
      ->json_is('/guards/1/rows/1/id',      $id3,                   'id ok do novo convite brazil')
      ->json_is('/guards/2/rows/0/nome',    'Expiraldo Silva',      'id ok')
      ->json_is('/guards/2/rows/0/id',      $row_to_be_removed->id, 'id ok');


};

done_testing();

exit;
