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

    my $left_config = [
        ["nome"            => 'Nome'],
        ["categoria"       => 'Categoria',       $categorias_hash],
        ["abrangencia"     => 'Abrangência',     $abragencia_options],
        ["cep"             => 'CEP',             {}],
        ["uf"              => "UF",              {}],
        ["municipio"       => "Município",       {}],
        ["nome_logradouro" => 'Nome Logradouro', {}],
        ["numero"          => "Número",          {}],
        ["complemento"     => 'Complemento',     {}],
        ["bairro"          => "Bairro",          {}],
        ["email"           => "E-mail",          {}],
        ["horario"         => "Horário",         {}],
        ["ddd1"            => "DDD 1",           {}],
        ["telefone1"       => "DDD 1",           {}],
        ["ddd2"            => "DDD 2",           {}],
        ["telefone2"       => "DDD 2",           {}],
        ["eh_24h"          => "É 24h?",          $yes_no_list_null],
        ["has_whatsapp"    => "Tem Whatsapp?",   $yes_no_list_null],
        ["observacao"      => "Observação",      {}],
    ];

    my $right_config = [
        ["nome"            => 'Nome'],
        ["categoria"       => 'Categoria',       $categorias_hash],
        ["abrangencia"     => 'Abrangência',     $abragencia_options],
        ["cep"             => 'CEP',             {}],
        ["uf"              => "UF",              {}],
        ["municipio"       => "Município",       {}],
        ["nome_logradouro" => 'Nome Logradouro', {}],
        ["numero"          => "Número",          {}],
        ["complemento"     => 'Complemento',     {}],
        ["bairro"          => "Bairro",          {}],
        ["email"           => "E-mail",          {}],
        ["horario"         => "Horário",         {}],
        ["ddd1"            => "DDD 1",           {}],
        ["telefone1"       => "DDD 1",           {}],
        ["ddd2"            => "DDD 2",           {}],
        ["telefone2"       => "DDD 2",           {}],
        ["eh_24h"          => "É 24h?",          $yes_no_list],
        ["has_whatsapp"    => "Tem Whatsapp?",   $yes_no_list],
        ["observacao"      => "Observação",      {}],
    ];



    my $fake_pa = {};

    return $c->respond_to_if_web(
        json => {
            json => {
                id => $row->{id},
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

1;
