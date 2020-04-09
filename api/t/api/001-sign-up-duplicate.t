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
        dt_nasc  => '9999-01-01',
        nome     => '404',
        situacao => '404',
    }
);

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
    },
)->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'cpf')->json_is('/reason', 'invalid');


$t->post_ok(
    '/signup',
    form => {
        nome_completo => 'aas asdas',
        cpf           => $valid_but_wrong_date,
        email         => $random_email,
        senha         => '123456',
        cep           => '12345678',
        genero        => 'Feminino',
        dt_nasc       => '1944-10-10',


    },
)->status_is(400)->json_is('/error', 'cpf_not_match');


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

    },
)->status_is(400)->json_is('/error', 'name_not_match');


my $res = $t->post_ok(
    '/signup',
    form => {
        nome_completo => 'test name',
        cpf           => $random_cpf,
        email         => $random_email,
        senha         => '123456',
        cep           => '12345678',
        genero        => 'Feminino',
        dt_nasc       => '1994-01-31',

    },
)->status_is(200)->tx->res->json;

$t->get_ok(
    '/me',
    {'x-api-key' => $res->{session}}
)->status_is(200);

$t->post_ok(
    '/logout',
    {'x-api-key' => $res->{session}}
)->status_is(204);

$t->get_ok(
    '/me',
    {'x-api-key' => $res->{session}}
)->status_is(403);

$t->post_ok(
    '/login',
    form => {
        email => $random_email,
        senha => '1234567'
    }
)->status_is(400)->json_is('/error', 'wrongpassword');


$res = $t->post_ok(
    '/login',
    form => {
        email => $random_email,
        senha => '123456'
    }
)->status_is(200)->json_has('/session')->json_is('/senha_falsa', 0)->tx->res->json;

$t->get_ok(
    '/me',
    {'x-api-key' => $res->{session}}
)->status_is(200);

use DDP;
p $res;

done_testing();

