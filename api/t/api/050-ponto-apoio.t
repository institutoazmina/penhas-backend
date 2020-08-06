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
    my $rand_cat = $schema2->resultset('PontoApoioCategoria')->search(
        {
            status => 'prod',
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            order_by     => \'RAND()',
            columns      => [qw/id label/],
            rows         => 1,
        }
    )->get_column('id')->next();

    my $first_sugg = $t->post_ok(
        '/sugerir-pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'endereco_ou_cep' => 'rua cupa, 255',
            nome              => 'foo',

            'categoria'         => $rand_cat,
            'descricao_servico' => 'aaa'
        }
    )->status_is(200)->json_has('/message', 'tem mensagem de sucesso')->json_has('/id', 'tem id durante os testes')
      ->tx->res->json;
    ok my $first_sugg_row = $schema2->resultset('PontoApoioSugestoe')->find($first_sugg->{id}),
      'row PontoApoioSugestoe is added';
    is $first_sugg_row->nome, 'foo', 'nome ok';
    is $first_sugg_row->cliente_id, $cliente_id, 'cliente_id ok';
    is $first_sugg_row->categoria, $rand_cat, 'cliente_id ok';

=pod

    $t->post_ok(
        '/sugerir-pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'nome'      => 'xaaaaaaaaaa',
            'sigla'     => 'lowercase',
            'natureza'  => 'publico',
            'categoria' => (
                $schema2->resultset('PontoApoioCategoria')->search(
                    {
                        status => 'prod',
                    },
                    {
                        result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                        order_by     => ['label'],
                        columns      => [qw/id label/],
                    }
                )->get_column('id')->next()
            ),
            'descricao'              => '',
            'eh_presencial'          => 0,
            'eh_online'              => 1,
            'cep'                    => '00000000',
            'tipo_logradouro'        => 'rua',
            'nome_logradouro'        => 'sem lugar',
            'numero_sem_numero'      => 1,
            'numero'                 => undef,
            'complemento'            => '',
            'bairro'                 => 'bar',
            'municipio'              => 'foo',
            'uf'                     => 'SP',
            'ddd'                    => 11,
            'telefone1'              => '953456789',
            'telefone2'              => '12345678',
            'email'                  => 'dunno@email.com',
            'eh_24h'                 => 0,
            'horario_inicio'         => '',
            'horario_fim'            => '00:11',
            'dias_funcionamento'     => 'dias_uteis',
            'funcionamento_pandemia' => undef,
            'observacao_pandemia'    => 'nao sei',
        }
    )->status_is(200)->json_has('/message', 'tem mensagem de sucesso');
=cut

};

done_testing();

exit;
