package Penhas::Controller::Admin::PontoApoio;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Penhas::Utils;
use DateTime;
use Penhas::Types qw/CEP/;
use MooseX::Types::Email qw/EmailAddress/;

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

    $row->{eh_whatsapp} = delete $row->{has_whatsapp};

    $row->{eh_24h}      = $row->{eh_24h}      ? 1 : defined $row->{eh_24h}      ? 0 : '';
    $row->{eh_whatsapp} = $row->{eh_whatsapp} ? 1 : defined $row->{eh_whatsapp} ? 0 : '';
    $row->{abrangencia} = ucfirst(lc($row->{abrangencia}));

    $row->{cep} =~ s/[^0-9]+//g if $row->{cep};
    $row->{uf} = uc($row->{uf});

    my $categorias_hash    = $c->ponto_apoio_categoria_options();
    my $abragencia_options = $c->ponto_apoio_abrangencia_options();

    my $yes_no_list_null = {
        options => [
            {value => '1', name => 'Sim'},
            {value => '0', name => 'Não'},
            {value => '',  name => '(nulo)'},
        ],
    };
    my $yes_no_list = {
        options => [
            {value => '1', name => 'Sim'},
            {value => '0', name => 'Não'},
        ],
    };

    my $dow = $c->ponto_apoio_dias_de_funcionamento_map();
    my $dias_list
      = {options => [sort { $a->{value} cmp $b->{value} } map { {value => $_, name => $dow->{$_}} } keys %$dow]};

    my $uf = $c->ponto_apoio_tipo_uf_map();
    my $uf_list
      = {options => [sort { $a->{value} cmp $b->{value} } map { {value => $_, name => $uf->{$_}} } keys %$uf]};

    my $tipo_logradouro      = $c->ponto_apoio_tipo_logradouro_map();
    my $tipo_logradouro_list = {
        options => [
            sort { $a->{value} cmp $b->{value} }
            map  { {value => $_, name => $tipo_logradouro->{$_}} } keys %$tipo_logradouro
        ]
    };

    my $left_config = [
        ["nome" => 'Nome'],
        [],
        ["categoria"   => 'Categoria',   $categorias_hash],
        ["abrangencia" => 'Abrangência', $abragencia_options],
        [],
        ["cep" => 'CEP', {}],
        [],
        ["uf"        => "UF",        $uf_list],
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
        ["ddd1"      => "DDD 1",      {}],
        ["ddd2"      => "DDD 2",      {}],
        ["telefone1" => "Telefone 1", {}],
        ["telefone2" => "Telefone 2", {}],
        [],
        [],
        ["eh_24h"      => "É 24h?",        $yes_no_list_null],
        ["eh_whatsapp" => "Tem Whatsapp?", $yes_no_list_null],
        ["observacao"  => "Observação",    {}],
    ];

    my $right_config = [
        ["nome"        => 'Nome * ⛃',],
        ["sigla"       => 'Sigla'],
        ["categoria"   => 'Categoria ⛃',   {%$categorias_hash}],
        ["abrangencia" => 'Abrangência *', {%$abragencia_options}],
        [
            "natureza" => "Natureza *",
            {options => [{value => 'ong', name => 'ONG'}, {value => 'publico', name => 'Público'}]}
        ],
        ["cep"                => 'CEP * ⛃',                   {}],
        ["cod_ibge"           => 'Código IBGE (Município) *', {}],
        ["uf"                 => "UF * ⛃",                    $uf_list],
        ["municipio"          => "Município * ⛃",             {}],
        ["tipo_logradouro"    => 'Tipo Logradouro *',         $tipo_logradouro_list],
        ["nome_logradouro"    => 'Nome Logradouro * ⛃',       {}],
        ["numero"             => "Número",                    {input_type              => 'number'}],
        ["numero_sem_numero"  => "Sem número? *",             {%$yes_no_list, required => 1}],
        ["latitude"           => "Latitude *",                {}],
        ["longitude"          => "Longitude *",               {}],
        ["complemento"        => 'Complemento',               {}],
        ["bairro"             => "Bairro * ⛃",                {required => 1}],
        ["email"              => "E-mail",                    {}],
        ["horario_inicio"     => "Horário Inicio",            {placeholder => 'HH:MM'}],
        ["horario_fim"        => "Horário Fim",               {placeholder => 'HH:MM'}],
        ["dias_funcionamento" => "Dias de Funcioamento",      $dias_list],
        ["ddd"                => "DDD",                       {input_type => 'number'}],
        [],
        ["telefone1"              => "Telefone 1",                  {input_type => 'number'}],
        ["telefone2"              => "Telefone 2",                  {input_type => 'number'}],
        ["ramal1"                 => "Ramal 1",                     {input_type => 'number'}],
        ["ramal2"                 => "Ramal 2",                     {input_type => 'number'}],
        ["eh_24h"                 => "É 24h?",                      $yes_no_list],
        ["eh_whatsapp"            => "Tem Whatsapp?",               $yes_no_list],
        ["observacao"             => "Observação (exibido no app)", {}],
        ["funcionamento_pandemia" => "Funciona na Pandemia?",       $yes_no_list_null],
        ["observacao_pandemia"    => "Observação Pandemia",         {}],
        ["descricao"              => "Descriação ⛃",                {}],
        ["delegacia_mulher"       => "Delegacia Mulher?",           $yes_no_list_null],
        ["horario_correto"        => "Horário Correto?",            $yes_no_list_null],
        ["endereco_correto"       => "Endereço Correto?",           $yes_no_list_null],
        ["telefone_correto"       => "Telefone Correto?",           $yes_no_list_null],
        ["existe_delegacia"       => "Existe Delegacia?",           $yes_no_list_null],
        ["eh_presencial"          => "É presencial?",               $yes_no_list_null],
        ["eh_online"              => "É online?",                   $yes_no_list_null],
    ];

    my $fake_pa = {};

    my $decoded = from_json($row->{saved_form});

    if (keys %$decoded == 0) {

        $fake_pa->{$_} = $row->{$_}
          for (
            qw/
            nome
            abrangencia
            categoria
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
            eh_whatsapp
            observacao
            /
          );

        if (!$fake_pa->{cod_ibge} && $fake_pa->{cep} && $fake_pa->{cep} =~ /^[\d-]+$/g) {
            $fake_pa->{cep} =~ s/[^0-9]+//g;
            my $res = &_search_cep($c, $fake_pa->{cep});
            if ($res->{ibge}) {
                &_patch_from_cep_result($c, $res, $fake_pa);
            }
        }

        if ($fake_pa->{numero} =~ /^\d+$/) {
            $fake_pa->{numero_sem_numero} = '0';
        }
        else {
            $fake_pa->{numero_sem_numero} = '1';
            $fake_pa->{numero}            = '';
        }

        $fake_pa->{ddd} = $row->{ddd1};
    }
    else {
        $fake_pa = $decoded;

        if ($fake_pa->{numero} =~ /^\d+$/) {
            $fake_pa->{numero_sem_numero} = '0';
        }
        else {
            $fake_pa->{numero_sem_numero} = '1';
            $fake_pa->{numero}            = '';
        }
    }


    use DDP;
    p $fake_pa;

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

    my $style = 'success_message';
    my $valid = $c->validate_request_params(
        id => {required => 1, type => 'Int'},
    );


    my $row = $c->schema2->resultset('PontoApoioSugestoesV2')->find($valid->{id})
      or $c->reply_item_not_found();

    my $taken_action = 'Rascunho salvo com sucesso!';
    my $params       = $c->req->params->to_hash;

    my $action = delete $params->{action};

    if ($action eq 'reprove') {

        $row->update({status => 'reproved'});

        if ($c->accept_html()) {
            $c->flash_to_redis({success_message => 'Sugestão reprovada com sucesso.'});
            $c->redirect_to('/admin');

            return 0;
        }
        else {
            return $c->render(
                json   => {ok => 1},
                status => 200,
            );
        }
    }
    elsif ($action eq 'load_cep') {
        my $valid_cep = $c->validate_request_params(
            cep => {required => 1, type => CEP},
        );
        $valid_cep->{cep} =~ s/[^0-9]+//g;
        my $res = &_search_cep($c, $valid_cep->{cep});

        if ($res->{ibge}) {
            $taken_action = 'Busca do endereço pelo CEP realizada com sucesso';

            &_patch_from_cep_result($c, $res, $params);
        }
        else {
            $taken_action = 'Erro ao buscar pelo CEP';
            $style        = 'message';
        }
    }
    elsif ($action eq 'geolocation') {

        my $valid_addr = $c->validate_request_params(
            tipo_logradouro => {required => 1, type => 'Str'},
            nome_logradouro => {required => 1, type => 'Str'},
            municipio       => {required => 1, type => 'Str'},
            uf              => {required => 1, type => 'Str'},
            cep             => {required => 1, type => 'Str'},
            numero          => {required => 0, type => 'Str', empty_is_valid => 1,},
        );

        my $full_addr = join ' ', $valid_addr->{tipo_logradouro},
          $valid_addr->{nome_logradouro}, ($valid_addr->{numero} ? $valid_addr->{numero} : ''), ',',
          $valid_addr->{uf},
          '-', $valid_addr->{municipio}, ',', $valid_addr->{cep};

        my $latlng = $c->geo_code_cached($full_addr);
        if ($latlng) {

            $taken_action = 'Sucesso ao localizar lat/lng para ' . $full_addr;
            ($params->{latitude}, $params->{longitude}) = split /,/, $latlng;
        }
        else {
            $taken_action = 'lat/lng para ' . $full_addr . ' não foi encontrado';
        }
    }

    $row->update({saved_form => to_json($params)});

    if ($action eq 'publish') {
        &try_publish_pa($c, $row);
        return;
    }

    if ($c->accept_html()) {
        $c->flash_to_redis({$style => $taken_action});
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

sub try_publish_pa {
    my ($c, $row) = @_;

    my $valid = $c->validate_request_params(
        nome                   => {required => 1, type => 'Str'},
        sigla                  => {required => 0, type => 'Str', empty_is_valid => 1},
        categoria              => {required => 1, type => 'Int'},
        abrangencia            => {required => 1, type => 'Str'},
        natureza               => {required => 1, type => 'Str'},
        cep                    => {required => 1, type => CEP},
        cod_ibge               => {required => 1, type => 'Str'},
        uf                     => {required => 1, type => 'Str'},
        municipio              => {required => 1, type => 'Str'},
        tipo_logradouro        => {required => 1, type => 'Str'},
        nome_logradouro        => {required => 1, type => 'Str'},
        numero                 => {required => 0, type => 'Int', empty_is_valid => 1},
        numero_sem_numero      => {required => 1, type => 'Bool'},
        latitude               => {required => 1, type => 'Num'},
        longitude              => {required => 1, type => 'Num'},
        complemento            => {required => 0, type => 'Str', empty_is_valid => 1},
        bairro                 => {required => 1, type => 'Str'},
        email                  => {required => 0, type => EmailAddress, empty_is_valid => 1},
        horario_inicio         => {required => 0, type => 'Str',        empty_is_valid => 1, max_lenght => 5},
        horario_fim            => {required => 0, type => 'Str',        empty_is_valid => 1, max_lenght => 5},
        dias_funcionamento     => {required => 0, type => 'Str',        empty_is_valid => 1},
        ddd                    => {required => 0, type => 'Int',        empty_is_valid => 1},
        telefone1              => {required => 0, type => 'Int',        empty_is_valid => 1},
        telefone2              => {required => 0, type => 'Int',        empty_is_valid => 1},
        ramal1                 => {required => 0, type => 'Int',        empty_is_valid => 1},
        ramal2                 => {required => 0, type => 'Int',        empty_is_valid => 1},
        eh_24h                 => {required => 0, type => 'Bool'},
        eh_whatsapp            => {required => 0, type => 'Bool'},
        observacao             => {required => 0, type => 'Str',  empty_is_valid => 1},
        funcionamento_pandemia => {required => 0, type => 'Bool', empty_is_valid => 1},
        observacao_pandemia    => {required => 0, type => 'Str',  empty_is_valid => 1},
        descricao              => {required => 0, type => 'Str',  empty_is_valid => 1},
        delegacia_mulher       => {required => 0, type => 'Bool', empty_is_valid => 1},
        horario_correto        => {required => 0, type => 'Bool', empty_is_valid => 1},
        endereco_correto       => {required => 0, type => 'Bool', empty_is_valid => 1},
        telefone_correto       => {required => 0, type => 'Bool', empty_is_valid => 1},
        existe_delegacia       => {required => 0, type => 'Bool', empty_is_valid => 1},
        eh_presencial          => {required => 0, type => 'Bool', empty_is_valid => 1},
        eh_online              => {required => 0, type => 'Bool', empty_is_valid => 1}
    );

    $valid->{cep} =~ s/[^0-9]+//g;
    $valid->{sigla} = uc($valid->{sigla}) if $valid->{sigla};

    for my $field (qw/horario_inicio horario_fim/) {
        $c->reply_invalid_param($field . ' inválido')
          if $valid->{$field} && $valid->{$field} !~ /^\d{2}\:\d{2}$/a;
    }

    $c->schema->txn_do(
        sub {
            $valid->{ja_passou_por_moderacao} = 1;

            $valid->{status}     = 'active';
            $valid->{created_on} = \'now()';
            $valid->{updated_at} = \'now()';
            $valid->{cliente_id} = $row->get_column('cliente_id');

            my $pa = $c->schema2->resultset('PontoApoio')->create($valid);

            my @auto_inserir
              = $c->schema2->resultset('PontoApoioProjeto')->search({auto_inserir => 1}, {columns => ['id']});

            for my $proj (@auto_inserir) {
                $c->schema2->resultset('PontoApoio2projeto')->create(
                    {
                        ponto_apoio_id         => $pa->id,
                        ponto_apoio_projeto_id => $proj->id,
                    }
                );
            }

            $c->tick_ponto_apoio_index();

            $row->update(
                {
                    metainfo => to_json(
                        {
                            %{from_json($row->metainfo())},
                            ponto_apoio_id => $pa->id,
                            approved_by    => $c->stash('admin_user')->id,
                        }
                    ),
                    status => 'approved',
                }
            );
        }
    );

    $c->flash_to_redis({success_message => 'Ponto de Apoio registrado!'});
    $c->redirect_to('/admin/');

}

sub _patch_from_cep_result {
    my ($c, $res, $params) = @_;

    $params->{cod_ibge}  = $res->{ibge};
    $params->{municipio} = $res->{localidade};
    $params->{bairro}    = $res->{bairro};
    $params->{uf}        = $res->{uf};

    foreach my $option (keys %{$c->ponto_apoio_tipo_logradouro_map()}) {
        my $value    = $c->ponto_apoio_tipo_logradouro_map()->{$option};
        my $option_q = quotemeta($value);

        if ($res->{logradouro} =~ /$option_q\s/) {
            $params->{nome_logradouro} = substr($res->{logradouro}, length($value) + 1);
            $params->{tipo_logradouro} = $value;
            last;
        }
        else {
            $params->{tipo_logradouro} = '';
            $params->{nome_logradouro} = $res->{logradouro};
        }
    }
}

sub _search_cep {
    my $c   = shift;
    my $cep = shift;

    my $res = $c->ua->get('https://viacep.com.br/ws/' . $cep . '/json/')->result->json;
    return $res;
}

1;
