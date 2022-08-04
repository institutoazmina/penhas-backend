package Penhas::Controller::Admin::PontoApoio;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Penhas::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Mojo::Util qw/humanize_bytes/;
use Penhas::Types qw/DateStr/;

sub apa_list {
    my $c = shift;
    $c->use_redis_flash();
    $c->stash(
        template => 'admin/ponto_apoio',
    );

    my $rs = $c->schema2->resultset('PontoApoioSugestoesV2')->search(
        {
            'me.status' => 'awaiting-moderation',
        },
        {
            join         => ['cliente', 'categoria'],
            order_by     => \'created_at DESC',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => [
                qw/
                  me.id
                  me.nome
                  me.created_at
                  categoria.label
                  cliente.nome_completo
                  cliente.id
                  /,
            ],
        }
    );

    my @rows = $rs->all;

    return $c->respond_to_if_web(
        json => {
            json => {
                rows => \@rows,
            }
        },
        html => {
            rows               => \@rows,
            pg_timestamp2human => \&pg_timestamp2human,
        },
    );
}

sub apa_review {
    my $c = shift;
    $c->use_redis_flash();
    $c->stash(
        template => 'admin/review_ponto_apoio',
    );

    my $valid = $c->validate_request_params(
        id => {required => 1, type => 'Int'},
    );

    my $row = $c->schema2->resultset('PontoApoioSugestoesV2')->search(
        {
            'me.status' => 'awaiting-moderation',
            'me.id'     => $valid->{id}
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->next;
    $c->reply_invalid_param('suggestion not found') unless $row;

    $row->{eh_24h}       = $row->{eh_24h}       ? 1 : defined $row->{eh_24h}       ? 0 : '';
    $row->{has_whatsapp} = $row->{has_whatsapp} ? 1 : defined $row->{has_whatsapp} ? 0 : '';
    $row->{abrangencia}  = ucfirst(lc($row->{abrangencia}));

    $row->{cep} =~ s/[^0-9]+//g;

    my $categorias_hash    = $c->ponto_apoio_categoria_options();
    my $abragencia_options = $c->ponto_apoio_abrangencia_options();

    my $yes_no_list_null = {
        options => [
            {value => '0', name => 'Não'},
            {value => '1', name => 'Sim'},
            {value => '',  name => '(nulo)'},
        ],
    };
    my $yes_no_list = {
        options => [
            {value => '0', name => 'Não'},
            {value => '1', name => 'Sim'},
        ],
    };

    my $dow       = $c->ponto_apoio_dias_de_funcionamento_map();
    my $dias_list = {options => [map { {value => $_, name => $dow->{$_}} } keys %$dow]};

    my $left_config = [
        ["nome" => 'Nome'],
        [],
        ["categoria"   => 'Categoria',   $categorias_hash],
        ["abrangencia" => 'Abrangência', $abragencia_options],
        ["cep"         => 'CEP',         {}],
        [],
        ["uf"        => "UF",        {}],
        ["municipio" => "Município", {}],
        [],
        ["nome_logradouro" => 'Nome Logradouro', {}],
        ["numero"          => "Número",          {}],
        [],
        [],
        [],
        ["complemento" => 'Complemento', {}],
        ["bairro"      => "Bairro",      {}],
        ["email"       => "E-mail",      {}],
        ["horario"     => "Horário",     {}],
        [],
        [],
        ["ddd1"         => "DDD 1",         {}],
        ["ddd2"         => "DDD 2",         {}],
        ["telefone1"    => "Telefone 1",    {}],
        ["telefone2"    => "Telefone 2",    {}],
        ["eh_24h"       => "É 24h?",        $yes_no_list_null],
        ["has_whatsapp" => "Tem Whatsapp?", $yes_no_list_null],
        ["observacao"   => "Observação",    {}],
    ];

    my $right_config = [
        ["nome"               => 'Nome ⛯ ⛃',],
        ["sigla"              => 'Sigla'],
        ["categoria"          => 'Categoria ⛃',             {%$categorias_hash}],
        ["abrangencia"        => 'Abrangência',             {%$abragencia_options}],
        ["cep"                => 'CEP ⛯ ⛃',                 {}],
        ["cod_ibge"           => 'Código IBGE (Município)', {}],
        ["uf"                 => "UF ⛯ ⛃",                  {}],
        ["municipio"          => "Município ⛯ ⛃",           {}],
        ["tipo_logradouro"    => 'Tipo Logradouro ⛯',       {}],
        ["nome_logradouro"    => 'Nome Logradouro ⛯ ⛃',     {}],
        ["numero"             => "Número",                  {input_type              => 'number'}],
        ["numero_sem_numero"  => "Sem número? ⛯",           {%$yes_no_list, required => 1}],
        ["latitude"           => "latitude",                {}],
        ["longitude"          => "longitude",               {}],
        ["complemento"        => 'Complemento',             {}],
        ["bairro"             => "Bairro ⛯ ⛃",              {required => 1}],
        ["email"              => "E-mail",                  {}],
        ["horario_inicio"     => "Horário Inicio",          {}],
        ["horario_fim"        => "Horário Fim",             {}],
        ["dias_funcionamento" => "Dias de Funcioamento",    $dias_list],
        ["ddd"                => "DDD",                     {}],
        [],
        ["telefone1"    => "Telefone 1",    {}],
        ["telefone2"    => "Telefone 2",    {}],
        ["eh_24h"       => "É 24h?",        $yes_no_list],
        ["has_whatsapp" => "Tem Whatsapp?", {%$yes_no_list, db_field => 'eh_whatsapp'}],
        ["observacao"   => "Observação",    {}],
        ["natureza"     => "Natureza ⛯",    {}],
        ["descricao"    => "Descriação ⛃",  {}],
    ];

    my $fake_pa = {};

    my $decoded = from_json($row->{saved_form});

    if (keys %$decoded == 0) {

        $fake_pa->{$_} = $row->{$_}
          for (
            qw/
            nome
            abrangencia
            nome_logradouro
            cep
            numero
            complemento
            bairro
            municipio
            uf
            telefone1
            telefone2
            email
            eh_24h
            has_whatsapp
            observacao
            /
          );
    }
    else {
        $fake_pa = $decoded;
    }

    return $c->respond_to_if_web(
        json => {
            json => {
                left_form => {
                    data   => $row,
                    fields => $left_config,
                },

                right_form => {
                    data   => $fake_pa,
                    fields => $right_config,
                },
            }
        },
        html => {
            left_form => {
                data   => $row,
                fields => $left_config,
            },

            right_form => {
                data   => $fake_pa,
                fields => $right_config,
            },

            pg_timestamp2human => \&pg_timestamp2human,
        },
    );

}

sub apa_review_post {
    my $c = shift;

    $c->use_redis_flash();

    my $valid = $c->validate_request_params(
        id => {required => 1, type => 'Int'},
    );


    my $row = $c->schema2->resultset('PontoApoioSugestoesV2')->find($valid->{id})
      or $c->reply_item_not_found();

    my $taken_action = 'Dados foram salvos com sucesso';
    my $params       = $c->req->params->to_hash;

    my $action = delete $params->{action};
    if ($action eq 'geolocation') {

    }


    $row->update({saved_form => to_json($params)});


    if ($c->accept_html()) {
        $c->flash_to_redis({success_message => $taken_action});
        $c->redirect_to('/admin/analisar-sugestao-ponto-apoio?id=' . $row->id);

        return 0;
    }
    else {
        return $c->render(
            json   => {ok => 1},
            status => 200,
        );
    }
}

1;
