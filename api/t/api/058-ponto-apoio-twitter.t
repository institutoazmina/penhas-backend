#!/usr/bin/perl
# HARNESS-CONFLICTS  PONTO_APOIO

use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;
my $t = test_instance;
my $json;
my $schema2 = get_schema2;

$ENV{FILTER_QUESTIONNAIRE_IDS} = '2';
$ENV{PONTO_APOIO_SECRET}       = 'validtoken';

my $ponto_apoio1;
my $ponto_apoio2;
my $ponto_apoio3;
&clear_ponto_apoio();
&insert_ponto_apoio();
on_scope_exit { &clear_ponto_apoio() };

$t->get_ok(
    '/ponto-apoio-unlimited',
    form => {
        token        => 'validtoken',
        latitude     => '-23.51934',
        longitude    => '-46.53918',
        rows         => 3,
        max_distance => 50,
    }
  )->status_is(200, 'valid response')    #
  ->json_like('/rows/0/nome', qr/ana rosa/)    #
  ->json_like('/rows/1/nome', qr/kazu/)        #
  ->json_like('/rows/2/nome', qr/trianon/)     #
  ->json_is('/rows/3', undef, '3 results');

$t->get_ok(
    '/ponto-apoio-unlimited',
    form => {
        token        => 'invalidtoken',
        latitude     => '-23.51934',
        longitude    => '-46.53918',
        rows         => 3,
        max_distance => 50,
    }
)->status_is(400, 'invalid response');

done_testing();

exit;

sub insert_ponto_apoio {
    my $cat1o = $schema2->resultset('PontoApoioCategoria')->create(
        {
            status => 'test',
            label  => 'cat1',
            color  => '#FFFFFF',
        }
    );
    my $proj = $schema2->resultset('PontoApoioProjeto')->create(
        {
            label  => 'testing is necessary',
            status => 'test',
        }
    );
    $cat1o->ponto_apoio_categoria2projetos->create({ponto_apoio_projeto_id => $proj->id});

    my $fields = {
        'sigla'                 => 'UPPER',
        'natureza'              => 'publico',
        'categoria'             => $cat1o->id,
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
        'dias_funcionamento'    => 'fds',
        'observacao_pandemia'   => 'nao sei',
        cliente_id              => undef,
        test_status             => 'test',
        ja_passou_por_moderacao => '1',
        status                  => 'active',
        created_on              => \'now()',
        updated_at              => \'now()',
    };

    foreach my $code (1 .. 3) {

        if ($code == 1) {
            $fields->{nome}      = 'trianon';
            $fields->{latitude}  = '-23.560311';
            $fields->{longitude} = '-46.658802';

        }
        elsif ($code == 2) {
            $fields->{nome}      = 'kazu';
            $fields->{latitude}  = '-23.571867';
            $fields->{longitude} = '-46.645901';

            $fields->{dias_funcionamento} = 'dias_uteis_fds_plantao';

        }
        elsif ($code == 3) {
            $fields->{nome}           = 'ana rosa';
            $fields->{latitude}       = '-23.581986';
            $fields->{longitude}      = '-46.638586';
            $fields->{qtde_avaliacao} = '10';
            $fields->{avaliacao}      = '4.164';

            $fields->{eh_24h}             = 1;
            $fields->{dias_funcionamento} = 'dias_uteis';
        }

        my $tmp = $schema2->resultset('PontoApoio')->create($fields);

        $ponto_apoio1 = $tmp if $code == 1;
        $ponto_apoio2 = $tmp if $code == 2;
        $ponto_apoio3 = $tmp if $code == 3;
    }
    $t->app->tick_ponto_apoio_index();
}

sub clear_ponto_apoio {
    $schema2->resultset('PontoApoio')->search({test_status => 'test'})->delete;
    $schema2->resultset('PontoApoioCategoria')->search({status => 'test'})->delete;
    $schema2->resultset('PontoApoioProjeto')->search({status => 'test'})->delete;
}
