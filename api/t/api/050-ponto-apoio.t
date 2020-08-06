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
            order_by => \'RAND()',
            columns  => [qw/id label projeto/],
            rows     => 1,
        }
    )->next();

    my $first_sugg = $t->post_ok(
        '/sugerir-pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'endereco_ou_cep' => 'rua cupa, 255',
            nome              => 'foo',

            'categoria'         => $rand_cat->id,
            'descricao_servico' => 'aaa'
        }
    )->status_is(200)->json_has('/message', 'tem mensagem de sucesso')->json_has('/id', 'tem id durante os testes')
      ->tx->res->json;
    ok my $first_sugg_row = $schema2->resultset('PontoApoioSugestoe')->find($first_sugg->{id}),
      'row PontoApoioSugestoe is added';
    is $first_sugg_row->nome, 'foo', 'nome ok';
    is $first_sugg_row->cliente_id, $cliente_id, 'cliente_id ok';
    is $first_sugg_row->categoria, $rand_cat->id, 'cliente_id ok';

    my $fields = {
        'sigla'               => 'lowercase',
        'natureza'            => 'publico',
        'categoria'           => $rand_cat->id,
        'descricao'           => '',
        'eh_presencial'       => 0,
        'eh_online'           => 1,
        'cep'                 => '00000000',
        'tipo_logradouro'     => 'rua',
        'nome_logradouro'     => 'sem lugar',
        'numero_sem_numero'   => 1,
        'numero'              => undef,
        'bairro'              => 'bar',
        'municipio'           => 'foo',
        'uf'                  => 'SP',
        'ddd'                 => 11,
        'telefone1'           => '953456789',
        'telefone2'           => '12345678',
        'email'               => 'dunno@email.com',
        'eh_24h'              => 0,
        'dias_funcionamento'  => 'dias_uteis',
        'observacao_pandemia' => 'nao sei',
        cliente_id            => $cliente_id,
        test_status           => 'test',
        created_on            => \'now()',
    };

    $schema2->resultset('PontoApoioCategoria')->search({status => 'test'})->delete;
    my $cat1 = $schema2->resultset('PontoApoioCategoria')->create(
        {
            status  => 'test',
            label   => 'cat1',
            projeto => $rand_cat->projeto,
        }
    )->id;
    my $cat2 = $schema2->resultset('PontoApoioCategoria')->create(
        {
            status  => 'test',
            label   => 'cat2',
            projeto => $rand_cat->projeto,
        }
    )->id;
    my $cat3 = $schema2->resultset('PontoApoioCategoria')->create(
        {
            status  => 'test',
            label   => 'cat3',
            projeto => $rand_cat->projeto,
        }
    )->id;

    $schema2->resultset('PontoApoio')->search({test_status => 'test'})->delete;
    foreach my $code (1 .. 3) {

        if ($code == 1) {
            $fields->{categoria} = $cat1;
            $fields->{nome}      = 'trianon';
            $fields->{latitude}  = '-23.560311';
            $fields->{longitude} = '-46.658802';

        }
        elsif ($code == 2) {
            $fields->{categoria} = $cat2;
            $fields->{nome}      = 'kazu';
            $fields->{latitude}  = '-23.571867';
            $fields->{longitude} = '-46.645901';

        }
        elsif ($code == 3) {

            $fields->{categoria} = $cat2;
            $fields->{nome}      = 'ana rosa';
            $fields->{latitude}  = '-23.581986';
            $fields->{longitude} = '-46.638586';
        }

        $schema2->resultset('PontoApoio')->create($fields);

    }

    # "vila mariana" ~ aprox 1.02 km de "ana rosa" em linha reta considerando a curvatura da terra
    # mas o algoritimo usado aqui só é uma aproximação do globo, com distorções nos polos e equador
    # -23.589893, -46.633462

    $t->get_ok(
        '/pontos-de-apoio',
        form => {
            'latitude'  => '-23.589893',
            'longitude' => '-46.633462',
        }
    )->status_is(200);

};

done_testing();

exit;
