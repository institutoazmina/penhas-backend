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

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';
$ENV{SKIP_END_NEWS}            = '1';

my @other_fields = (
    raca        => 'branco',
    apelido     => 'guardioes',
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

my ($cliente_id, $session, $cliente);
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
            genero      => rand() > 0.5 ? 'Feminino' : 'MulherTrans',
            nome_social => 'foo bar',
        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    $session    = $res->{session};
    $cliente    = $schema2->resultset('Cliente')->find($cliente_id);
};

on_scope_exit { user_cleanup(user_id => $cliente_id); };


do {
    is $cliente->clientes_app_activities->count, 0, 'no clientes_app_activities';
    $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200, 'da um get pra marcar o clientes_app_activities');
    is $cliente->clientes_app_activities->count, 1, 'clientes_app_activities exists';

    $Penhas::Helpers::Chat::ForceFilterClientes = [$cliente_id];
    $t->get_ok(
        '/search-users',
        {'x-api-key' => $session}
    )->status_is(200, 'listando usuarios');

};

done_testing();

exit;
