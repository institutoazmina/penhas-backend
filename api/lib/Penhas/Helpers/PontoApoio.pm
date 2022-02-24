package Penhas::Helpers::PontoApoio;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Number::Phone::Lib;
use Penhas::Utils qw/random_string_from is_test tt_render/;
use Digest::MD5 qw/md5_hex/;
use Mojo::Util qw/trim/;
use Scope::OnExit;
use Text::CSV_XS;
use Encode qw/encode_utf8/;


sub setup {
    my $self = shift;

    $self->helper('ponto_apoio_list'       => sub { &ponto_apoio_list(@_) });
    $self->helper('ponto_apoio_fields'     => sub { &ponto_apoio_fields(@_) });
    $self->helper('ponto_apoio_suggest'    => sub { &ponto_apoio_suggest(@_) });
    $self->helper('ponto_apoio_rating'     => sub { &ponto_apoio_rating(@_) });
    $self->helper('ponto_apoio_detail'     => sub { &ponto_apoio_detail(@_) });
    $self->helper('tick_ponto_apoio_index' => sub { &tick_ponto_apoio_index(@_) });
    $self->helper('_project_id_by_label'   => sub { &_project_id_by_label(@_) });
    $self->helper('_ponto_apoio_csv'       => sub { &_ponto_apoio_csv(@_) });
}


sub _format_pa_row {
    my ($c, $user_obj, $row) = @_;

    return {
        (map { $_ => $row->$_ } qw/id/),
    };
}

sub _project_id_by_label {
    my ($c, %opts) = @_;
    my $filter_projeto_id;
    if (exists $opts{projeto} && $opts{projeto}) {
        my $projeto = $c->schema2->resultset('PontoApoioProjeto')->search(
            {
                status => is_test() ? 'test' : 'prod',
                label  => $opts{projeto}
            }
        )->next;
        $c->reply_invalid_param('Não encontrado', 'form_error', 'projeto') unless $projeto;
        $filter_projeto_id = $projeto->id;
    }
    return $filter_projeto_id;
}

sub _ponto_apoio_csv {
    my ($c, $rs, $filename) = @_;
    $rs = $rs->reset;

    my $csv = Text::CSV_XS->new({binary => 1, auto_diag => 1});

    # and write as CSV
    open my $fh, ">:encoding(utf8)", $filename or die "cannot open for write $filename: $!";

    my @fields = (
        ['nome',                   'Nome'],
        ['sigla',                  'Sigla'],
        ['natureza',               'Natureza'],
        ['categoria_nome',         'Categoria'],
        ['tipo_logradouro',        'Tipo logradouro'],
        ['nome_logradouro',        'Nome logradouro'],
        ['numero',                 'Número'],
        ['complemento',            'Complemento'],
        ['bairro',                 'Bairro'],
        ['municipio',              'Município'],
        ['uf',                     'UF'],
        ['cep',                    'cep'],
        ['ddd',                    'ddd'],
        ['telefone1',              'telefone1'],
        ['telefone2',              'telefone2'],
        ['ramal1',                 'ramal1'],
        ['ramal2',                 'ramal2'],
        ['email',                  'e-mail'],
        ['eh_24h',                 '24horas', 'bool'],
        ['horario_inicio',         'Horário início'],
        ['horario_fim',            'Horário fim'],
        ['dias_funcionamento',     'Dias funcionamento'],
        ['eh_presencial',          'Presencial',             'bool'],
        ['eh_online',              'Online',                 'bool'],
        ['funcionamento_pandemia', 'Funcionamento pandemia', 'bool'],
        ['observacao_pandemia',    'Observação pandemia'],
        ['latitude',               'Latitude'],
        ['longitude',              'Longitude'],
        ['verificado',             'Verificado',       'bool'],
        ['existe_delegacia',       'Existe delegacia', 'bool'],
        ['delegacia_mulher',       'Delegacia Mulher'],
        ['endereco_correto',       'Endereço correto', 'bool'],
        ['horario_correto',        'Horário correto',  'bool'],
        ['telefone_correto',       'Telefone correto', 'bool'],
        ['observacao',             'Observação'],
        ['eh_whatsapp',            'Whatsapp', 'bool'],
        ['abrangencia',            'Abrangencia',],
        ['cod_ibge',               'cod_ibge',],
        ['id',                     'ID'],
    );
    $csv->say($fh, [map { $_->[1] } @fields]);

    while (my $r = $rs->next) {
        my @cols;
        foreach (@fields) {
            my $v = $r->{$_->[0]};
            if (defined $v) {
                if ($_->[2] && $_->[2] eq 'bool') {
                    push @cols, $v ? 'Sim' : 'Não';
                }
                else {
                    push @cols, $v;
                }
            }
            else {
                push @cols, '';
            }
        }
        $csv->say($fh, [@cols]);
    }
    close $fh or die "cannot close $filename: $!";
    return {file => $filename};
}

# filtro por nota
# filtro por projeto
# filtro por categoria
# ordem por distancia (pegar lat long)
# filtro por nome (generico)

sub ponto_apoio_list {
    my ($c, %opts) = @_;

    local $Data::Dumper::Maxdepth = 2;
    log_debug('ponto_apoio_list args: ' . $c->app->dumper(\%opts));

    my $user_obj = $opts{user_obj};

    my $latitude    = $opts{latitude};
    my $longitude   = $opts{longitude};
    my $as_csv      = $opts{as_csv};
    my $all_columns = $opts{all_columns};

    # just in case, pra nao rolar sql injection, mas aqui já deve ter validado isso no controller
    confess '$latitude is not valid'
      if defined $latitude && $latitude !~ /^(([-+]?(([1-8]?\d(\.\d+))+|90)))$/ao;
    confess '$longitude is not valid'
      if defined $longitude
      && $longitude !~ /^([-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?))$/ao;


    my $keywords     = trim(lc($opts{keywords} || ''));
    my $max_distance = $opts{max_distance} || 50;

    my $categorias         = $opts{categorias};
    my $eh_24h             = exists $opts{eh_24h}             ? $opts{eh_24h}             : undef;
    my $dias_funcionamento = exists $opts{dias_funcionamento} ? $opts{dias_funcionamento} : undef;

    confess '$categorias is not arrayref' if $categorias && ref $categorias ne 'ARRAY';

    my $filter_projeto_id = $c->_project_id_by_label(%opts);

    # se nao passar qual projeto, filtra sozinho para o projeto da web (mapa da delegacia)
    $filter_projeto_id = $ENV{FILTER_PONTO_APOIO_PROJETO_WEB}
      if $ENV{FILTER_PONTO_APOIO_PROJETO_WEB} && !$as_csv && !$filter_projeto_id;

    $c->reply_invalid_param('Distância precisa ser menor que 5000km', 'form_error', 'max_distance')
      if $max_distance > 5000;
    $c->reply_invalid_param('Distância precisa ser maior que 1km', 'form_error', 'max_distance')
      if $max_distance < 1;

    my $offset = 0;
    if ($opts{next_page}) {
        my $tmp = eval { $c->decode_jwt($opts{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'PA:NP';
        $offset = $tmp->{offset};
    }

    my $rows = $opts{rows} || 100;
    $rows = 100 if !is_test() && ($rows > 5000 || $rows < 3);

    if ($as_csv) {
        $rows      = -1;
        $latitude  = undef;
        $longitude = undef;
    }
    if ($max_distance == 5000) {
        $rows = -1;
    }

    my $user_cod_ibge = -1;

    if (defined $latitude) {
        $user_cod_ibge = $c->cod_ibge_by_latlng($latitude, $longitude);

        # faz o fallback pro CEP do user
        if (!$user_cod_ibge && $user_obj) {
            log_debug('cod_ibge not found, trying again by geo_code_cached_by_user');
            ($latitude, $longitude) = $c->geo_code_cached_by_user($user_obj);

            $c->reply_invalid_param('Localização do CEP não é válida') if (!$latitude);

            log_trace('cep_fallback');

            $user_cod_ibge = $c->cod_ibge_by_latlng($latitude, $longitude);
            log_debug("geo_code_cached_by_user($latitude, $longitude) is $user_cod_ibge");
        }

        if (!$user_cod_ibge) {
            $user_cod_ibge = -1;
        }
    }
    log_trace('user_cod_ibge', $user_cod_ibge);

    #Sempre apresentar o que for "Nacional"
    # Sempre apresentar o "local" do município em que a pessoa está
    # (com fallback para o CEP da pessoa caso não tenha esteja dentro do local)
    # Regional sempre filtrar por 50km (e não filtrar por estado)

    my $distance_in_km_where = defined $latitude
      ? qq|
          CASE WHEN abrangencia = 'Nacional' THEN (TRUE)
          WHEN abrangencia = 'Regional' THEN ( cod_ibge = '$user_cod_ibge'::int OR '$user_cod_ibge'::int = -1 )
          ELSE
            (ST_DWithin(me.geog, ST_SetSRID(ST_MakePoint( $longitude , $latitude ), 4326)::geography, (($max_distance+1) * 1000) - 1))
          END
       |
      : '';

    my $distance_in_km_column = defined $latitude
      ? qq| CASE
            WHEN abrangencia = 'Nacional' THEN -0.0001
            ELSE floor(ST_Distance(me.geog, ST_SetSRID(ST_MakePoint( $longitude , $latitude ), 4326)::geography ) / 1000 )
            END |
      : '';

    my $search = {
        'me.test_status' => is_test() ? 'test' : 'prod',

        #'me.ja_passou_por_moderacao' => 1,
        'me.status' => 'active',

        ($categorias ? ('me.categoria' => {in => $categorias}) : ()),

        ($distance_in_km_where ? ('-and' => [\$distance_in_km_where,]) : ()),
    };
    my $attr = {
        (($as_csv || $all_columns) ? '+columns' : 'columns') => [
            (
                $rows == -1 ? () : (
                    {distance_in_km => \"$distance_in_km_column AS distance_in_km"},
                )
            ),
            {categoria_nome => 'categoria.label'},
            {categoria_cor  => 'categoria.color'},
            {categoria_id   => 'categoria.id'},
            {categoria_id   => 'categoria.id'},
            ($user_obj ? ({cliente_avaliacao => 'cliente_ponto_apoio_avaliacaos.avaliacao'}) : ()),
            qw/me.id me.nome me.latitude me.longitude me.avaliacao me.uf me.qtde_avaliacao/,
        ],
        join => [
            'categoria',
            ($user_obj ? ('cliente_ponto_apoio_avaliacaos') : ()),
        ],

        result_class => 'DBIx::Class::ResultClass::HashRefInflator',

        (
            $rows == -1
            ? (
                order_by => \'me.id',
              )
            : (
                order_by => \'distance_in_km ASC',
                rows     => $rows + 1,
                offset   => $offset,
            )
        )
    };

    do {
        local $Data::Dumper::Maxdepth = 3;
        log_debug($c->app->dumper($search, $attr));
    };

    my $rs = $c->schema2->resultset('PontoApoio')->search($search, $attr);

    if ($keywords) {
        log_debug("keywords original: $keywords");
        $rs = $rs->search(
            {
                '-and' => [
                    \[
                        "to_tsvector('pg_catalog.portuguese', index)
                        @@
                        plainto_tsquery('pg_catalog.portuguese',
                            unaccent(?::text)
                        )",
                        $keywords
                    ]
                ]
            }
        );
    }

    $rs = $rs->search({'index' => {like => "%`p$filter_projeto_id]]%"}})
      if defined $filter_projeto_id;

    $rs = $rs->search({'eh_24h'             => $eh_24h ? 1 : 0})     if defined $eh_24h;
    $rs = $rs->search({'dias_funcionamento' => $dias_funcionamento}) if defined $dias_funcionamento;

    if ($as_csv) {
        my $max_updated_at = $rs->search(undef, {order_by => undef})->get_column('updated_at')->max();
        my $filename       = $max_updated_at . 'v1';
        $filename .= "proj$filter_projeto_id"     if defined $filter_projeto_id;
        $filename .= $eh_24h ? "eh24h" : '!eh24h' if defined $eh_24h;
        $filename .= $dias_funcionamento          if defined $dias_funcionamento;
        $filename .= $keywords                    if defined $keywords;
        if ($categorias) {
            $filename .= "cat" . $_ for sort $categorias->@*;
        }
        $filename = $ENV{PONTO_APOIO_CACHE_DIR} . '/' . md5_hex(encode_utf8($filename)) . '.csv';

        return {file => $filename} if -e $filename;

        return $c->_ponto_apoio_csv($rs, $filename);
    }

    #log_debug($c->app->dumper([rows => $rows]));

    my @rows      = $rs->all;
    my $cur_count = scalar @rows;
    my $has_more  = $rows != -1 && $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }
    foreach (@rows) {

        $_->{avaliacao} = sprintf('%.01f', $_->{avaliacao});
        $_->{avaliacao} =~ s/\./,/;
        $_->{avaliacao} = 'n/a' if delete $_->{qtde_avaliacao} == 0;
        if ($rows > 0) {
            if ($_->{distance_in_km} == -0.0001) {

                $_->{distancia} = 'Nacional - 0 ';

                # passa por cima
                $_->{latitude}  = $latitude;
                $_->{longitude} = $longitude;
            }
            else {
                $_->{distancia}
                  = ($_->{abrangencia} eq 'Regional' ? 'Regional - ' : '') . int(delete $_->{distance_in_km}) . '';
            }
        }
        $_->{categoria} = {
            id   => delete $_->{categoria_id},
            cor  => delete $_->{categoria_cor},
            nome => delete $_->{categoria_nome},
        };
    }
    log_debug($c->app->dumper([rows => $rows]));

    my $next_page = $c->encode_jwt(
        {
            iss    => 'PA:NP',
            offset => $offset + $cur_count,
        },
        1
    );

    return {
        rows             => \@rows,
        has_more         => $has_more,
        next_page        => $has_more ? $next_page : undef,
        avaliacao_maxima => '5',
        latitude         => $latitude,
        longitude        => $longitude,

        #_debug => {
        #    max_distance       => $max_distance,
        #    keywords           => $keywords,
        #    rows               => $rows,
        #    offset             => $offset,
        #    eh_24h             => $eh_24h,
        #    dias_funcionamento => $dias_funcionamento,
        #}
    };
}

sub ponto_apoio_fields {
    my ($c, %opts) = @_;

    my $is_public = defined $opts{format} && $opts{format} eq 'public';

    my @config = (


        ['endereco_ou_cep' => {max_length => 255, required => 1,},],
        ['nome'            => {max_length => 255, required => 1,},],

        [
            'categoria' => {required => 1},
            {
                options => [
                    map { +{value => $_->{id}, name => $_->{label}} }
                      $c->schema2->resultset('PontoApoioCategoria')->search(
                        {
                            status => 'prod',
                        },
                        {
                            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                            order_by     => ['label'],
                            columns      => [qw/id label/],
                        }
                    )->all()

                ]
            }
        ],
        ['descricao_servico' => {required => 1, max_length => 9999,},],

    );

    my $ret;

    my %names = (
        endereco_ou_cep   => 'Endereço ou CEP',
        descricao_servico => 'Descrição do serviço',
        nome              => 'Nome',
    );
    foreach my $item (@config) {

        $item->[1]{type}     = 'Str' unless exists $item->[1]{type};
        $item->[1]{required} = 0     unless exists $item->[1]{required};

        if ($is_public) {
            my %tmp = defined $item->[2] ? $item->[2]->%* : ();

            push $ret->@*, {
                code => $item->[0],
                name => (
                    exists $names{$item->[0]}
                    ? $names{$item->[0]}
                    : &_gen_name_from_code($item->[0])
                ),
                $item->[1]->%*,
                %tmp,
            };
        }
        else {
            $item->[1]{empty_is_invalid} = 0;
            push $ret->@*, $item->[0], $item->[1];
        }
    }

    return $ret;
}

sub _gen_name_from_code {
    my ($code) = @_;

    $code =~ s/_/ /;
    $code = join ' ', map { ucfirst($_) } split ' ', $code;

    return $code;
}


sub ponto_apoio_suggest {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    my $fields = $opts{fields};

    $fields->{cliente_id} = $user_obj->id;
    $fields->{metainfo}   = to_json(
        {
            ip => $c->remote_addr(),
        }
    );
    $fields->{created_at} = \'now()';


    my $row = $c->schema2->resultset('PontoApoioSugestoe')->create($fields);

    if ($ENV{EMAIL_PONTO_APOIO_SUGESTAO}) {
        $c->schema->resultset('EmaildbQueue')->create(
            {
                config_id => 1,
                template  => 'ponto_apoio_sugestao.html',
                to        => $ENV{EMAIL_PONTO_APOIO_SUGESTAO},
                subject   => 'PenhaS - Nova sugestão de ponto de apoio',
                variables => encode_json(
                    {
                        id => $row->id(),
                    }
                ),
            }
        );
    }

    return {
        success => 1,
        message => 'Sua sugestão será avaliada antes de ser publicada.',
        title   => 'Sugestão recebida',
        (is_test() ? (id => $row->id) : ()),
    };
}

sub ponto_apoio_rating {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    my $ponto_apoio_id = $opts{ponto_apoio_id};
    my $rating         = $opts{rating};

    my $remove = $opts{remove} ? $opts{remove} : 0;

    if (!$remove) {
        $c->reply_invalid_param('precisa ser entre 0 e 5', 'form_error', 'rating')
          if !defined $rating || $rating > 5 || $rating < 0;
    }

    my $ponto_apoio = $c->schema2->resultset('PontoApoio')->find($ponto_apoio_id);
    $c->reply_invalid_param('ponto de apoio não encontrado', 'form_error', 'ponto_apoio_id')
      unless $ponto_apoio;

    $c->schema2->txn_do(
        sub {
            my $filtered = $user_obj->cliente_ponto_apoio_avaliacaos->search(
                {
                    ponto_apoio_id => $ponto_apoio_id,
                }
            );
            $filtered->delete;
            if (!$remove) {
                $filtered->create(
                    {
                        avaliacao  => $rating,
                        created_at => \'NOW()',
                    }
                );
            }

            my $agg = $ponto_apoio->cliente_ponto_apoio_avaliacaos->search(
                undef,
                {
                    columns => [
                        {
                            avaliacao      => \'coalesce( avg(avaliacao), 0)',
                            qtde_avaliacao => \'count(1)'
                        }
                    ],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                }
            )->next;
            $ponto_apoio->update($agg);
        }
    );
}

sub ponto_apoio_detail {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj};
    my $id       = $opts{id};
    $c->reply_invalid_param('ponto_apoio_id') if !$id || $id !~ /^\d+$/a;

    my $row = $c->schema2->resultset('PontoApoio')->search(
        {
            'me.test_status' => is_test() ? 'test' : 'prod',

            #'me.ja_passou_por_moderacao' => 1,
            'me.status' => 'active',
            'me.id'     => $id,
        },
        {
            'columns' => [
                {categoria_nome => 'categoria.label'},
                {categoria_cor  => 'categoria.color'},
                {categoria_id   => 'categoria.id'},
                {categoria_id   => 'categoria.id'},
                (
                    $user_obj
                    ? ({cliente_avaliacao => 'cliente_ponto_apoio_avaliacaos.avaliacao'})
                    : ()
                ),
                qw/
                  me.id
                  me.nome
                  me.latitude
                  me.longitude
                  me.avaliacao
                  me.cep
                  me.tipo_logradouro
                  me.nome_logradouro
                  me.municipio
                  me.uf
                  me.bairro
                  me.qtde_avaliacao
                  me.natureza
                  me.descricao
                  me.numero
                  me.numero_sem_numero
                  me.complemento
                  me.ddd
                  me.telefone1
                  me.telefone2
                  me.ramal1
                  me.ramal2
                  me.eh_24h
                  me.eh_whatsapp
                  me.horario_inicio
                  me.horario_fim
                  me.dias_funcionamento
                  me.eh_presencial
                  me.eh_online
                  me.funcionamento_pandemia
                  me.observacao_pandemia
                  me.ja_passou_por_moderacao
                  me.observacao
                  /,
            ],
            join => [
                'categoria',
                ($user_obj ? ('cliente_ponto_apoio_avaliacaos') : ()),
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->next;
    $c->reply_item_not_found() unless $row;

    my $cliente_avaliacao = delete $row->{cliente_avaliacao};

    $row->{avaliacao} = sprintf('%.01f', $row->{avaliacao});
    $row->{avaliacao} =~ s/\./,/;
    $row->{avaliacao} = 'n/a' if delete $row->{qtde_avaliacao} == 0;
    $row->{categoria} = {
        id   => delete $row->{categoria_id},
        cor  => delete $row->{categoria_cor},
        nome => delete $row->{categoria_nome},
    };
    my $natureza_de_para = {
        publico => 'Público',
        ong     => 'ONG',
    };
    $row->{natureza} = $natureza_de_para->{$row->{natureza}} || $row->{natureza};


    my $dow_de_para = {
        'dias_uteis'             => 'Dias úteis',
        'fds'                    => 'Fim de semana',
        'dias_uteis_fds_plantao' => 'Dias úteis com plantão aos fins de semana',
        'todos_os_dias'          => 'Todos os dias',
        'seg_a_sab'              => 'Segunda a sábado',
        'seg_a_qui'              => 'Segunda a quinta',
        'ter_a_qui'              => 'Terça a quinta',
        'quinta_feira'           => 'Quintas-feiras',
    };
    $row->{dias_funcionamento}
      = $dow_de_para->{$row->{dias_funcionamento}} || $row->{dias_funcionamento};

    if ($user_obj) {
        $row->{content_html} = tt_render(
                q|[% IF observacao%] <p style="color: #0a115f">[% observacao %]</p><br/>[% END %]|
              . q|<p style="color: #0a115f"><b>Endereço</b></p>|
              . q|<p style="color: #818181;">[% tipo_logradouro %] [% nome_logradouro %]|
              . q|[% IF numero.defined() %], [% numero %][% END %] -[%bairro %] -[%municipio %], [%uf %], [%cep %] </p>|
              . q|[% IF ddd.defined() %]<p> [% telefone2 ? 'Telefones' :'Telefone' %]: <a href="tel:+55[%ddd%][%telefone1%]">[% ddd %] [% telefone1 %]</a> [% IF ramal1.defined() %] ramal: [% ramal1 %] [% END %]
                    [% IF telefone2%], <a href="tel:+55[%ddd%][%telefone2%]">[% ddd %] [% telefone2 %]</a> [% IF ramal2.defined() %] ramal: [% ramal2 %] [% END %] [% END %]
              </p>[% ELSE %]
                    [% IF telefone1 %] Telefone: [%telefone1%] [% END %]
                    [% IF telefone2 %], [%telefone2%] [% END %]
              [% END %]
              [%IF dias_funcionamento%]
                <p>Horário de funcionamento: [%dias_funcionamento%]
                  [%IF horario_inicio %]<br/>
                    [% horario_inicio %] - [% horario_fim %] </p>
                  [% END %]
                  </p>
              [% END %]
              |,

            $row
        );
    }

    return {
        ponto_apoio => $row,
        (
            $user_obj
            ? (
                cliente_avaliacao => $cliente_avaliacao,
              )
            : ()
        ),
        avaliacao_maxima => '5',
    };
}

sub tick_ponto_apoio_index {
    my ($c) = @_;
    log_debug('tick_ponto_apoio_index started');

    my $pg_schema = $c->schema;

    my $rs = $c->schema2->resultset('PontoApoio')->search(
        {
            test_status => is_test() ? 'test' : 'prod',

            '-or' => [
                {indexed_at => undef},
                {indexed_at => {'<' => \'updated_at'}},
            ],
        },
        {
            rows     => 1000,
            prefetch => 'ponto_apoio2projetos'
        }
    );

    my $rows = 0;
    my $now  = time();
    while (my $ponto = $rs->next) {
        my $index    = '';
        my @projetos = map { $_->ponto_apoio_projeto_id() } $ponto->ponto_apoio2projetos->all;
        foreach my $projeto_id (@projetos) {
            $index .= '`p' . $projeto_id . ']]';
        }
        $index .= ' ' . $ponto->categoria->label;

        $index .= ' ' . ($ponto->$_() || '') for qw/
          nome
          sigla
          descricao
          municipio
          nome_logradouro
          bairro
          uf
          cep/;
        $index = $pg_schema->unaccent($index);
        $index = lc($index);

        $ponto->update(
            {
                indexed_at => \'updated_at',
                index      => $index
            }
        );
        $rows++;
        last if time() - $now > 50;
    }
    log_debug("tick_ponto_apoio_index reindex $rows rows");

    return 1;
}

1;
