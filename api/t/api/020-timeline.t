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
    apelido     => 'oshiete yo',
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

    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'like'),
        {'x-api-key' => $session},
    )->status_is(200)->json_is('/qtde_likes', 1);

    my $comment1 = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'comment'),
        {'x-api-key' => $session},
        form => {content => 'mata itsuka'}
    )->status_is(200)->tx->res->json;

    # busca timeline principal
    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session}
    )->status_is(200)->json_is('/has_more', '0')->json_is('/tweets/0/content', 'ijime dame zettai')
      ->json_is('/tweets/0/id', $tweet_id);

    # busca comentarios
    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session},
        form => {parent_id => $tweet_id}
    )->status_is(200)->json_is('/has_more', '0')->json_is('/tweets/0/content', 'mata itsuka')
      ->json_is('/tweets/0/id', $comment1->{id});

    for (1 .. 2) {
        $t->post_ok(
            '/me/tweets',
            {'x-api-key' => $session},
            form => {
                content => 'Kazoeru ' . $_,
            }
        )->status_is(200);
    }
    my $page1=$t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session},
        form => {
            rows => 2,
        }
    )->status_is(200)->json_is('/has_more', '1')->json_is('/tweets/0/content', 'Kazoeru 2')
      ->json_is('/tweets/1/content', 'Kazoeru 1')->tx->res->json;

    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session},
        form => {
            rows => 2,
            before => $page1->{tweets}[-1]->{id}
        }
    )->status_is(200)->json_is('/has_more', '0')->json_is('/tweets/0/content', 'ijime dame zettai')
      ->json_is('/tweets/1/content', undef);

    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'report'),
        {'x-api-key' => $session},
        form => {reason => 'this offends me'}
    )->status_is(200);


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
