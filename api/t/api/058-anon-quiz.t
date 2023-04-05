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
$ENV{ANON_QUIZ_SECRET}         = 'validtoken';


my $ponto_apoio1;
my $ponto_apoio2;
my $ponto_apoio3;
&clear_ponto_apoio();
&insert_ponto_apoio();
on_scope_exit { &clear_ponto_apoio() };

$t->get_ok('/anon-questionnaires')->status_is(400, 'missing token')->json_is('/field', 'token')
  ->json_is('/reason', 'is_required');

$t->get_ok(
    '/anon-questionnaires',
    form => {token => 'wrong'}
)->status_is(400, 'invalid token')->json_is('/field', 'token')->json_is('/reason', 'invalid');

$t->get_ok(
    '/anon-questionnaires',
    form => {token => 'validtoken'}
)->status_is(200, 'valid response')->json_is('/questionnaires/0/name', 'anon-test')
  ->json_is('/questionnaires/0/id', 2, 'loaded correct questionnaire');


$t->get_ok(
    '/anon-questionnaires/config',
    form => {token => 'validtoken'}
)->status_is(200, 'valid response');

my $res_first = $t->post_ok(
    '/anon-questionnaires/new',
    form => {
        token     => 'validtoken',  questionnaire_id => 2,
        remote_id => 'test-remote', init_responses   => '{"foo":"bar"}'
    }
)->status_is(200, 'valid response')->tx->res->json;
ok $res_first->{quiz_session}{session_id}, 'has session_id';

is trace_popall(), 'anon_new_quiz_session:created', 'quiz_session was created';

$t->get_ok(
    '/anon-questionnaires/history',
    form => {
        token      => 'validtoken',
        session_id => 0,
    }
)->status_is(400, 'not valid session_id')->json_is('/field', 'session_id');

my $res_history = $t->get_ok(
    '/anon-questionnaires/history',
    form => {
        token      => 'validtoken',
        session_id => $res_first->{quiz_session}{session_id},
    }
)->status_is(200, 'valid response')->tx->res->json;

is trace_popall(), 'anon_load_quiz_session:loaded', 'quiz_session was loaded';
is $res_first, $res_history, 'is the same response';

my $input = $res_first->{quiz_session}{current_msgs}[-1];
ok $input, 'has input';
is $input->{type},    'onlychoice', 'is onlychoice';
ok $input->{ref},     'has ref';
is $input->{content}, 'choose one', 'content ok';
is $input->{code},    'chooseone',  'is chooseone';

# responde a primeira opção
my $res_second = $t->post_ok(
    '/anon-questionnaires/process',
    form => {
        token         => 'validtoken',
        session_id    => $res_first->{quiz_session}{session_id},
        $input->{ref} => 0,
    }
)->status_is(200, 'valid response')->tx->res->json;

# cep01 - cep_address_lookup
my $input = $res_second->{quiz_session}{current_msgs}[-1];
ok $input, 'has input';
is $input->{type},    'text', 'is text [cep_address_lookup]';
ok $input->{ref},     'has ref';
is $input->{content}, 'digite seu cep', 'content ok';
is $input->{code},    'cep_01',         'is cep_01';

# responde com um cep inválido
$t->post_ok(
    '/anon-questionnaires/process',
    form => {
        token         => 'validtoken',
        session_id    => $res_first->{quiz_session}{session_id},
        $input->{ref} => 0,
    }
)->status_is(200, 'invalid response')
  ->json_like('/quiz_session/current_msgs/0/content', qr/Não encontrei dígitos suficiente para começar/);

$t->post_ok(
    '/anon-questionnaires/process',
    form => {
        token         => 'validtoken',
        session_id    => $res_first->{quiz_session}{session_id},
        $input->{ref} => 'abc',
    }
)->status_is(200, 'invalid response')
  ->json_like('/quiz_session/current_msgs/0/content', qr/Não encontrei os dígitos para buscar o CEP/);

$t->post_ok(
    '/anon-questionnaires/process',
    form => {
        token         => 'validtoken',
        session_id    => $res_first->{quiz_session}{session_id},
        $input->{ref} => '03610-0200',
    }
)->status_is(200, 'invalid response')
  ->json_like('/quiz_session/current_msgs/0/content', qr/Encontrei dígitos demais para buscar o CEP/);


my $res_results = $t->post_ok(
    '/anon-questionnaires/process',
    form => {
        token         => 'validtoken',
        session_id    => $res_first->{quiz_session}{session_id},
        $input->{ref} => '03610-020',
    }
  )->status_is(200, 'invalid response')    #
  ->json_like('/quiz_session/current_msgs/0/content', qr/resultados que encontrei/)    #
  ->json_like('/quiz_session/current_msgs/1/content', qr/ana rosa/)                    #
  ->json_like('/quiz_session/current_msgs/2/content', qr/kazu/)                        #
  ->json_like('/quiz_session/current_msgs/3/content', qr/trianon/)                     #
  ->json_is('/quiz_session/current_msgs/4/content', 'olá')                             #
  ->tx->res->json;                                                                     #

# btn-fim
$input = $res_results->{quiz_session}{current_msgs}[-1];
ok $input, 'has input';
is $input->{type},    'button', 'is button';
ok $input->{ref},     'has ref';
ok $input->{content}, 'has content';
is $input->{label},   'Finalizar', 'label ok';
is $input->{code},    'botao_fim', 'has code (because it is anon)';

my $res_end = $t->post_ok(
    '/anon-questionnaires/process',
    form => {
        token         => 'validtoken',
        session_id    => $res_first->{quiz_session}{session_id},
        $input->{ref} => 1,
    }
)->status_is(200, 'valid response')->tx->res->json;

is $res_end->{quiz_session}{finished}, 1, 'finished';

$t->get_ok(
    '/anon-questionnaires/history',
    form => {
        token      => 'validtoken',
        session_id => $res_first->{quiz_session}{session_id},
    }
)->status_is(200, 'full history is 200 after finished, but is missing content');


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

    # parece não existir mais
    #$cat1o->ponto_apoio_categoria2projetos->create({ponto_apoio_projeto_id => $proj->id});

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
        'abrangencia'           => 'Local',
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
