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
AGAIN2:
my $random_cpf2   = random_cpf();
my $random_email2 = 'email' . $random_cpf2 . '@something.com';
goto AGAIN2 if cpf_already_exists($random_cpf2);

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';

my @other_fields = (
    raca        => 'pardo',
    apelido     => 'oshiete yo',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

my $nome_completo  = 'test name xsxs';
my $nome_completo2 = 'sawano souzou';
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
        nome_hashed => cpf_hash_with_salt(uc $nome_completo2),
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


my ($cliente_id2, $session2);
subtest_buffered 'Cadastro2 com sucesso' => sub {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => $nome_completo2,
            cpf           => $random_cpf2,
            email         => $random_email2,
            senha         => '123456',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero => 'Feminino',

        },
    )->status_is(200)->tx->res->json;

    $cliente_id2 = $res->{_test_only_id};
    $session2    = $res->{session};
};

$Penhas::Helpers::Timeline::ForceFilterClientes = [$cliente_id, $cliente_id2];
on_scope_exit { user_cleanup(user_id => $Penhas::Helpers::Timeline::ForceFilterClientes); };

subtest_buffered 'cadastro' => sub {
    my $cadastro = $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200)->tx->res->json;

    is $cadastro->{user_profile}{nome_completo}, $nome_completo;
    is $cadastro->{user_profile}{nome_social}, '', 'nome social nao existe em genero=feminino';

    ok grep {/timeline/} $cadastro->{modules}->@*, 1, 'modulo timeline presente';
};

my $tweet_rs = app->schema2->resultset('Tweet');
subtest_buffered 'Tweet' => sub {

    my $media = $t->post_ok(
        '/me/media',
        {'x-api-key' => $session},
        form => {
            intention => 'tweet',
            media     => {file => "$RealBin/../data/small.png"}
        },

    )->status_is(200)->tx->res->json;

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
    )->status_is(200)->json_is('/tweet/qtde_likes', 1)->json_is('/tweet/meta/liked', 1);

    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'like'),
        {'x-api-key' => $session},
        form => {remove => '1'}
    )->status_is(200)->json_is('/tweet/qtde_likes', 0)->json_is('/tweet/meta/liked', 0);

    my $comment1 = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'comment'),
        {'x-api-key' => $session},
        form => {content => 'mata itsuka', media_ids => $media->{id}}
    )->status_is(200)->tx->res->json;
    is $tweet_rs->find($comment1->{id})->ultimo_comentario_id, undef, 'ultimo_comentario_id tem q ser vazio';

    is $tweet_rs->find($tweet_id)->ultimo_comentario_id, $comment1->{id}, 'ultimo_comentario_id tem q ser a resposta';

    # busca timeline principal como autor
    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session}
    )->status_is(200)->json_is('/has_more', '0')->json_is('/tweets/0/content', 'ijime dame zettai')
      ->json_is('/tweets/0/id', $tweet_id)->json_is('/tweets/0/meta/liked', 0)->json_is('/tweets/0/meta/owner', 1)
      ->json_is('/tweets/0/last_reply/id', $comment1->{id})->json_is('/tweets/0/last_reply/meta/liked', 0);

    # busca timeline principal como outro usuario
    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session2}
    )->status_is(200)->json_is('/has_more', '0')->json_is('/tweets/0/content', 'ijime dame zettai')
      ->json_is('/tweets/0/id', $tweet_id)->json_is('/tweets/0/meta/liked', 0)->json_is('/tweets/0/meta/owner', 0)
      ->json_is('/tweets/0/last_reply/id', $comment1->{id})->json_is('/tweets/0/last_reply/meta/liked', 0);

    # da um like com o segundo usuario
    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'like'),
        {'x-api-key' => $session2},
    )->status_is(200)->json_is('/tweet/qtde_likes', 1);

    # repetir o like like nao pode aumentar a quantidade
    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'like'),
        {'x-api-key' => $session2},
    )->status_is(200)->json_is('/tweet/qtde_likes', 1);
    # pode dar like depois de ter removido o like
    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'like'),
        {'x-api-key' => $session},
    )->status_is(200)->json_is('/tweet/qtde_likes', 2);


    # busca o detalhe de um tweet especifico
    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session},
        form => {parent_id => $tweet_id}
    )->status_is(200)->json_is('/has_more', '0')->json_is('/tweets/0/content', 'mata itsuka')
      ->json_is('/tweets/0/id', $comment1->{id});

    # adicionando mais tweets para testar a paginacao
    for (1 .. 2) {
        $t->post_ok(
            '/me/tweets',
            {'x-api-key' => $session},
            form => {
                content => 'Kazoeru ' . $_,
            }
        )->status_is(200);
    }
    my $page1 = $t->get_ok(
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
            rows   => 2,
            before => $page1->{tweets}[-1]->{id}
        }
    )->status_is(200)->json_is('/order_by', 'latest_first')->json_is('/has_more', '0')
      ->json_is('/tweets/0/content', 'ijime dame zettai')->json_is('/tweets/1/content', undef);

    # pega o primeiro tweet apos o primeiro tweet ever
    # que na realidade eh o reply, mas tem que filtrar e trazer o Kazoeru 1
    # sempre que filtra usando AFTER o index inverte e traz primeiro os mais antigos (asc)
    my $ret_after = $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session},
        form => {
            rows  => 1,
            after => $tweet_id
        }
    )->status_is(200)->json_is('/order_by', 'oldest_first')->json_is('/has_more', '1')
      ->json_is('/tweets/0/content', 'Kazoeru 1')->json_is('/tweets/1/content', undef)->tx->res->json;

    # pega todos os proximos
    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session},
        form => {
            rows  => 100,
            after => $ret_after->{tweets}[0]{id}
        }
    )->status_is(200)->json_is('/tweets/0/content', 'Kazoeru 2')->json_is('/tweets/1/content', undef)
      ->json_is('/has_more', '0');

    # reportando um tweet
    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'report'),
        {'x-api-key' => $session},
        form => {reason => 'this offends me'}
    )->status_is(200);

    # verifica o filtro de "apenas eu"
    $t->post_ok(
        '/me/tweets',
        {'x-api-key' => $session2},
        form => {
            content => 'Just me',
        }
    )->status_is(200);
    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session2},
        form => {only_myself => 1, rows => 1}
    )->status_is(200)->json_is('/has_more', '0')->json_is('/tweets/0/content', 'Just me')
      ->json_is('/tweets/1/content', undef);

    $t->get_ok(
        ('/timeline'),
        {'x-api-key' => $session2},
        form => {skip_myself => 1, rows => 2}
    )->status_is(200)->json_is('/has_more', '1')->json_is('/tweets/0/content', 'Kazoeru 2');

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
