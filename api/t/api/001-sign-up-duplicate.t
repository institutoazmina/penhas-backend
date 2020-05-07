use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;

my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;

AGAIN:
my $random_cpf           = random_cpf();
my $bad_random_cpf       = random_cpf(0);
my $valid_but_wrong_date = '89253398035';

my $random_email = 'email' . $random_cpf . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf);

$ENV{MAX_CPF_ERRORS_IN_24H} = 10000;

my @other_fields = (
    raca        => 'pardo',
    apelido     => 'ca',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf      => $random_cpf,
        dt_nasc  => '1994-01-31',
        nome     => 'test name',
        situacao => '',
    }
);
get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf      => $valid_but_wrong_date,
        dt_nasc  => '1944-10-10',
        nome     => '404',
        situacao => '404',
    }
);

subtest_buffered 'Erro na criação de conta' => sub {
    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $bad_random_cpf,
            email         => $random_email,
            senha         => '123456',
            cep           => '12345678',
            genero        => 'Feminino',
            dt_nasc       => '1994-10-10',
            @other_fields,
        },
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'cpf')->json_is('/reason', 'invalid');


    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $valid_but_wrong_date,
            cep           => '12345678',
            dt_nasc       => '1944-10-10',
            @other_fields,
            dry => 1,
        },
    )->status_is(400)->json_is('/error', 'cpf_not_match');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'test name',
            cpf           => $random_cpf,
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            dry => 1,

        },
    )->status_is(200)->json_is('/continue', '1');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '123456',
            cep           => '12345678',
            genero        => 'Feminino',
            dt_nasc       => '1994-01-31',
            @other_fields,

        },
    )->status_is(400)->json_is('/error', 'name_not_match');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'test name',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '123456',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero => 'MulherTrans',
        },
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'nome_social')
      ->json_is('/reason', 'is_required');
};

my $cliente_id;
subtest_buffered 'Cadastro com sucesso' => sub {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'test name',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '123456',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            nome_social   => 'foobar lorem',
            @other_fields,
            genero        => 'MulherTrans',

        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    my $cadastro = $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(200)->tx->res->json;

    is $cadastro->{user_profile}{nome_completo}, 'test name';
    is $cadastro->{user_profile}{nome_social}, 'foobar lorem';


    $t->post_ok(
        '/logout',
        {'x-api-key' => $res->{session}}
    )->status_is(204);

    $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(403);
};

my $session;
subtest_buffered 'Login' => sub {
    $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => '1234567',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(400)->json_is('/error', 'wrongpassword');

    my $res = $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => '123456',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(200)->json_has('/session')->json_is('/senha_falsa', 0)->tx->res->json;

    $session = $res->{session};
    $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(200);

};

my $directus = get_cliente_by_email($random_email);
subtest_buffered 'Contador login com senha falsa' => sub {

    is $directus->{qtde_login_senha_falsa}, 0, 'qtde_login_senha_falsa is 0';
    $t->post_ok(
        '/me/increment-fake-password-usage',
        {'x-api-key' => $session}
    )->status_is(204);

    $directus = get_cliente_by_email($random_email);
    is $directus->{qtde_login_senha_falsa}, 1, 'qtde_login_senha_falsa increased';
};

subtest_buffered 'Reset de senha' => sub {

    is(get_forget_password_row($directus->{id}), undef, 'no rows');

    $t->post_ok(
        '/reset-password/request-new',
        form => {
            email       => $random_email,
            app_version => '...',
        }
    )->status_is(200);

    ok(my $forget = get_forget_password_row($directus->{id}), 'has a new row');
    ok $forget->{token}, 'has token';
    is $forget->{used_at}, undef, 'used_at is null';

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 1,
            token       => '12345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'invalid_token');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => '12345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 1,
            token       => $forget->{token},
            senha       => 'abc12345678',
            app_version => '...',
        }
    )->status_is(200)->json_is('/continue', '1');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => $forget->{token},
            senha       => 'abc12345678',
            app_version => '...',
        }
    )->status_is(200)->json_is('/success', '1');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => $forget->{token},
            senha       => 'abc12345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'invalid_token');

    ok($forget = get_forget_password_row($directus->{id}), 'has a new row');
    ok $forget->{used_at}, 'used_at is NOT null';

    $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => 'abc12345678',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(200)->json_has('/session')->json_is('/senha_falsa', 0)->tx->res->json;

};


user_cleanup(user_id => $cliente_id);

done_testing();

exit;
