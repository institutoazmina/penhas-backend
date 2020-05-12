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

my @other_fields = (
    raca        => 'pardo',
    apelido     => 'ca',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

my $nome_completo = 'test name xsxs';
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
            nome_social   => 'foobar lorem',
            @other_fields,
            genero => 'Feminino',

        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    $session    = $res->{session};
};

on_scope_exit { user_cleanup(user_id => $cliente_id); };

subtest_buffered 'Tweet' => sub {

    my $cadastro = $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200)->tx->res->json;

    is $cadastro->{user_profile}{nome_completo}, $nome_completo;
    is $cadastro->{user_profile}{nome_social}, '', 'nome social nao existe em genero=feminino';

    ok grep {/timeline/} $cadastro->{modules}->@*, 1, 'modulo timeline presente';

    my $res = $t->post_ok(
        '/me/tweets',
        {'x-api-key' => $session},
        form => {
            content => 'ijime dame zettai',
        }
    )->status_is(200)->tx->res->json;
    my $tweet_id = $res->{id};

    my $like_res = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'like'),
        {'x-api-key' => $session},
    )->status_is(200)->tx->res->json;

use DDP; p $like_res;

    $t->delete_ok(
        '/me/tweets',
        {'x-api-key' => $session},
        form => {
            id => $tweet_id,
        }
    )->status_is(204);

};


done_testing();

exit;
