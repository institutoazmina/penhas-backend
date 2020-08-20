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

&reset_db();

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

    $schema2->resultset('GeoCache')->search({key => ['12345-678 brasil', 'r. teste', '-23.55597,-46.66266', 'r. foo']})
      ->delete;
    $schema2->resultset('GeoCache')->create(
        {
            key         => '12345-678 brasil',
            value       => '-23.555995,-46.662665',    # começo da consolação
            created_at  => \'NOW()',
            valid_until => '2055-01-01',
        }
    );

    # a chave -23.55597,-46.66266 eh diferente pq ta arredondando 1m
    $schema2->resultset('GeoCache')->create(
        {
            key         => '-23.55597,-46.66266',
            value       => 'Cerqueira César, São Paulo, SP, Brasil',    # começo da consolação
            created_at  => \'NOW()',
            valid_until => '2055-01-01',
        }
    );
    $schema2->resultset('GeoCache')->create(
        {
            key         => 'r. teste',
            value       => '-23.555995,-46.662665',                       # começo da consolação
            created_at  => \'NOW()',
            valid_until => '2055-01-01',
        }
    );

    $schema2->resultset('GeoCache')->create(
        {
            key         => 'r. foo',
            value       => '',                                            # caso de 404
            created_at  => \'NOW()',
            valid_until => '2055-01-01',
        }
    );

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
        '/me/sugerir-pontos-de-apoio',
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
        'sigla'                 => 'UPPER',
        'natureza'              => 'publico',
        'categoria'             => $rand_cat->id,
        'descricao'             => '',
        'eh_presencial'         => 0,
        'eh_online'             => 1,
        'cep'                   => '00000000',
        'tipo_logradouro'       => 'rua',
        'nome_logradouro'       => 'sem lugar',
        'numero_sem_numero'     => 1,
        'numero'                => undef,
        'bairro'                => 'bar',
        'municipio'             => 'foo',
        'uf'                    => 'SP',
        'ddd'                   => 11,
        'telefone1'             => '953456789',
        'telefone2'             => '12345678',
        'email'                 => 'dunno@email.com',
        'eh_24h'                => 0,
        'dias_funcionamento'    => 'dias_uteis',
        'observacao_pandemia'   => 'nao sei',
        cliente_id              => $cliente_id,
        test_status             => 'test',
        ja_passou_por_moderacao => '1',
        status                  => 'active',
        created_on              => \'now()',
    };

    my $cat1 = $schema2->resultset('PontoApoioCategoria')->create(
        {
            status  => 'test',
            label   => 'cat1',
            projeto => $rand_cat->projeto,
            color   => '#FFFFFF',
        }
    )->id;
    my $cat2 = $schema2->resultset('PontoApoioCategoria')->create(
        {
            status  => 'test',
            label   => 'cat2',
            projeto => $rand_cat->projeto,
            color   => '#FF00FF',
        }
    )->id;
    my $cat3 = $schema2->resultset('PontoApoioCategoria')->create(
        {
            status  => 'test',
            label   => 'cat3',
            projeto => $rand_cat->projeto,
        }
    )->id;

    my $avaliar_ponto_apoio;
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

            # tambem categoria 2
            $fields->{categoria}      = $cat2;
            $fields->{nome}           = 'ana rosa';
            $fields->{latitude}       = '-23.581986';
            $fields->{longitude}      = '-46.638586';
            $fields->{qtde_avaliacao} = '10';
            $fields->{avaliacao}      = '4.164';
        }

        my $tmp = $schema2->resultset('PontoApoio')->create($fields);

        if ($code == 3) {
            $avaliar_ponto_apoio = $tmp;
        }
    }

    # "vila mariana" ~ aprox 1.02 km de "ana rosa" em linha reta considerando a curvatura da terra
    # mas o algoritimo usado aqui só é uma aproximação do globo, com distorções nos polos e equador
    # -23.589893, -46.633462

    $t->get_ok(
        '/pontos-de-apoio',
        form => {
            'latitude'   => '-23.589893',
            'longitude'  => '-46.633462',
            'categorias' => join(',', $cat1, $cat2, $cat3)    # filtrar por tudo nao deve ter nenhum efeito
        }
      )->status_is(200)                                       #
      ->json_is('/rows/0/distancia',     1,          'mais proximo primeiro')
      ->json_is('/rows/1/distancia',     2,          'esta ficando menos proximo')
      ->json_is('/rows/2/distancia',     4,          '4 km eh a distancia final ')
      ->json_is('/rows/0/nome',          'ana rosa', 'nome certo')                   #
      ->json_is('/rows/0/categoria/cor', '#FF00FF',  'categoria cor certa')          #
      ->json_is('/rows/0/latitude',      -23.581986, 'posicao latitude esta ok')     #
      ->json_is('/rows/0/longitude',     -46.638586, 'posicao longitude')            #
      ->json_is('/rows/0/avaliacao',     '4,2',      'ta fazendo o round certo')     #
      ->json_is('/rows/1/avaliacao',     'n/a',      'nao tem pq tem zero')          #
      ->json_is('/rows/2/avaliacao',     'n/a',      'nao tem pq tem zero')          #
      ->json_is('/has_more',             0,          'has more is false')            #
      ->json_is('/avaliacao_maxima',     5,          'avaliacao_maxima')             #
      ->json_is('/next_page',            undef,      'next_page is empty');


    $t->get_ok(
        '/pontos-de-apoio',
        form => {
            'latitude'     => '-23.589893',
            'longitude'    => '-46.633462',
            'max_distance' => 1,
        }
      )->status_is(200)                                                              #
      ->json_is('/rows/0/distancia', 1,     'mais proximo primeiro')                 #
      ->json_is('/rows/1',           undef, 'fora do range de distancia')            #
      ->json_is('/has_more',         0,     'has more is false');

    $t->get_ok(
        '/pontos-de-apoio',
        form => {
            'latitude'   => '-23.589893',
            'longitude'  => '-46.633462',
            'categorias' => $cat3,
        }
      )->status_is(200)                                                              #
      ->json_is('/rows/0',   undef, 'nao tem ninguem na categoria 3')                #
      ->json_is('/has_more', 0,     'has more is false');

    $t->get_ok(
        '/pontos-de-apoio',
        form => {
            'latitude'   => '-23.589893',
            'longitude'  => '-46.633462',
            'categorias' => $cat1,
        }
      )->status_is(200)                                                              #
      ->json_is('/rows/0/nome', 'trianon', 'trianon eh o registro')                  #
      ->json_is('/rows/1',      undef,     'apenas 1 registro na cat1')              #
      ->json_is('/has_more',    0,         'has more is false');


    my $res1 = $t->get_ok(
        '/pontos-de-apoio',
        form => {
            'latitude'  => '-23.589893',
            'longitude' => '-46.633462',
            'rows'      => 2,
        }
      )->status_is(200)                                                              #
      ->json_is('/rows/0/distancia', 1,     'mais proximo primeiro')                 #
      ->json_is('/rows/1/distancia', 2,     'esta ficando menos proximo')            #
      ->json_is('/rows/2',           undef, 'nao tem terceiro item')                 #
      ->json_is('/has_more',         1,     'has more is true')                      #
      ->json_has('/next_page', 'but still has next_page token')->tx->res->json;

    $t->get_ok(
        '/pontos-de-apoio',
        form => {
            'latitude'  => '-23.589893',
            'longitude' => '-46.633462',
            'rows'      => 2,
            'next_page' => $res1->{next_page},
        }
      )->status_is(200)                                                              #
      ->json_is('/rows/0/distancia', 4,     'mais longe')                            #
      ->json_is('/rows/1',           undef, 'nao tem segundo')                       #
      ->json_is('/has_more',         0,     'has more is false')                     #
      ->json_has('/next_page', 'but still has next_page token')->tx->res->json;

    $t->get_ok(
        '/pontos-de-apoio',
        form => {
            'latitude'  => '-23.589893',
            'longitude' => '-46.633462',
            'keywords'  => 'kaz',
        }
      )->status_is(200)                                                              #
      ->json_is('/rows/0/nome', 'kazu', 'kazu eh o resultado pra busca')             #
      ->json_is('/rows/1',      undef,  'nao tem mais')                              #
      ->json_is('/has_more',    0);

    my $rand_zero_to_five = int(rand(6));
    $t->post_ok(
        '/me/avaliar-pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'ponto_apoio_id' => $avaliar_ponto_apoio->id,
            'rating'         => $rand_zero_to_five
        }
    )->status_is(204);

    $t->post_ok(
        '/me/avaliar-pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'ponto_apoio_id' => $avaliar_ponto_apoio->id,
            'rating'         => 6
        }
    )->status_is(400)->json_is('/field', 'rating');

    $t->post_ok(
        '/me/avaliar-pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'ponto_apoio_id' => $avaliar_ponto_apoio->id * 555000,
            'rating'         => 5
        }
    )->status_is(400)->json_is('/field', 'ponto_apoio_id');

    $t->get_ok(
        '/me/pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'latitude'  => '-23.589893',
            'longitude' => '-46.633462',
            'keywords'  => $avaliar_ponto_apoio->nome,
        }
      )->status_is(200)    #
      ->json_is('/rows/0/cliente_avaliacao', $rand_zero_to_five)           #
      ->json_is('/rows/0/id',                $avaliar_ponto_apoio->id)     #
      ->json_is('/rows/0/avaliacao',         $rand_zero_to_five . ',0')    #
      ->json_is('/rows/1',                   undef, 'nao tem mais')        #
      ->json_is('/has_more',                 0);

    $avaliar_ponto_apoio->discard_changes;
    is $avaliar_ponto_apoio->qtde_avaliacao, 1, 'uma avaliação';

    # passando sem enviar location, tem q buscar via CEP, que vai trazer os mais proximos da consolação antes
    $t->get_ok(
        '/me/pontos-de-apoio',
        {'x-api-key' => $session},
        form => {}
      )->status_is(200)                                                    #
      ->json_is('/rows/0/nome',      'trianon')                            #
      ->json_is('/rows/1/nome',      'kazu')                               #
      ->json_is('/rows/2/nome',      'ana rosa')                           #
      ->json_is('/rows/0/distancia', '0')                                  #
      ->json_is('/rows/1/distancia', '2')                                  #
      ->json_is('/rows/2/distancia', '3')                                  #
      ->json_is('/has_more',         0);

    # passando sem enviar location, tem q buscar via CEP, que vai trazer os mais proximos da consolação antes
    my $token1 = $t->get_ok(
        '/geocode',
        {},
        form => {address => 'R. Teste'}
      )->status_is(200)                                                    #
      ->json_is('/label', 'Cerqueira César, São Paulo, SP, Brasil')      #
      ->json_has('/location_token', 'has token')->tx->res->json;

    $t->get_ok(
        '/geocode',
        {},
        form => {address => 'R. Foo'}
      )->status_is(400)                                                    #
      ->json_has('/error')                                                 #
      ->json_hasnt('/location_token');

    my $token2 = $t->get_ok(
        '/me/geocode',
        {'x-api-key' => $session},
        form => {address => 'R. Teste'}
    )->status_is(200)->tx->res->json;
    is $t->app->decode_jwt($token1->{location_token}), $t->app->decode_jwt($token2->{location_token}), 'same token';

    # faz o request sem usuario, passando o location_token
    $t->get_ok(
        '/pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            location_token => $token1->{location_token},
        }
      )->status_is(200)    #
      ->json_is('/rows/0/nome',      'trianon')     #
      ->json_is('/rows/1/nome',      'kazu')        #
      ->json_is('/rows/2/nome',      'ana rosa')    #
      ->json_is('/rows/0/distancia', '0')           #
      ->json_is('/rows/1/distancia', '2')           #
      ->json_is('/rows/2/distancia', '3')           #
      ->json_is('/has_more',         0);

    $t->get_ok(
        '/me/pontos-de-apoio/' . $avaliar_ponto_apoio->id,
        {'x-api-key' => $session}
      )->status_is(200)                             #
      ->json_is('/cliente_avaliacao', $rand_zero_to_five, 'avalicao ok')    #
      ->json_has('/ponto_apoio')                                            #
      ->json_has('/cliente_avaliacao');

    $t->get_ok(
        '/pontos-de-apoio/' . $avaliar_ponto_apoio->id,                     #
      )->status_is(200)                                                     #
      ->json_hasnt('/cliente_avaliacao')                                    #
      ->json_has('/avaliacao_maxima')                                       #
      ->json_is('/ponto_apoio/avaliacao',          $rand_zero_to_five . ',0', 'tem nota avaliacao')             #
      ->json_is('/ponto_apoio/cep',                '00000000',                'tem cep')                        #
      ->json_is('/ponto_apoio/natureza',           'Público',                'tem natureza traduzida')         #
      ->json_is('/ponto_apoio/dias_funcionamento', 'Dias úteis',             'tem Dia Da semana traduzido')    #
      ->json_is('/ponto_apoio/numero',             undef,                     'sem numero');                    #


    $t->post_ok(
        '/me/avaliar-pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'ponto_apoio_id' => $avaliar_ponto_apoio->id,
            'rating'         => 0
        }
    )->status_is(204, 'avaliar com 0 is ok');
    $avaliar_ponto_apoio->discard_changes;
    is $avaliar_ponto_apoio->qtde_avaliacao, 1, 'ainda tem apenas 1 avaliacao';

    $t->post_ok(
        '/me/avaliar-pontos-de-apoio',
        {'x-api-key' => $session},
        form => {
            'ponto_apoio_id' => $avaliar_ponto_apoio->id,
            'remove'         => 1
        }
    )->status_is(204);
    $avaliar_ponto_apoio->discard_changes;
    is $avaliar_ponto_apoio->qtde_avaliacao, 0, 'nao te mais avaliacao';
};

done_testing();

&reset_db();
exit;

sub reset_db {
    $schema2->resultset('PontoApoio')->search({test_status => 'test'})->delete;
    $schema2->resultset('PontoApoioCategoria')->search({status => 'test'})->delete;

}