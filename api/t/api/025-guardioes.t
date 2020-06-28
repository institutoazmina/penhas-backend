use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;

my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;


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
    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            apelido => 'test apelido',
            celular => '11 81144666',
        }
    )->status_is(400)->json_is('/error', 'parser_error', 'numero nao existe no brasil')->json_is('/field', 'celular')
      ->json_is('/reason', 'invalid');

    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            apelido => 'test apelido',
            celular => '11 31144666',
        }
    )->status_is(400)->json_is('/error', 'number_is_not_mobile', 'numero nao eh celular')
      ->json_is('/field', 'celular')->json_is('/reason', 'invalid');


    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            apelido => 'apelido!!',
            celular => '+14842918467',
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '+1 484-291-8467')
      ->json_is('/data/nome',       'test nome')->json_is('/data/apelido', 'apelido!!')->json_is('/data/is_pending', '1')
      ->json_is('/data/is_expired', '0')->json_is('/data/is_accepted', '0')->json_like('/message', qr/SMS/);

};

done_testing();

exit;
