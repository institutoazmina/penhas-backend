package Penhas::Helpers::PontoApoio;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Number::Phone::Lib;
use Penhas::Utils qw/random_string_from is_test/;
use Digest::MD5 qw/md5_hex/;
use Mojo::Util qw/trim/;
use Scope::OnExit;

sub setup {
    my $self = shift;

    $self->helper('ponto_apoio_list'    => sub { &ponto_apoio_list(@_) });
    $self->helper('ponto_apoio_fields'  => sub { &ponto_apoio_fields(@_) });
    $self->helper('ponto_apoio_suggest' => sub { &ponto_apoio_suggest(@_) });
    $self->helper('ponto_apoio_rating'  => sub { &ponto_apoio_rating(@_) });
    $self->helper('ponto_apoio_detail'  => sub { &ponto_apoio_detail(@_) });
}


sub _format_pa_row {
    my ($c, $user_obj, $row) = @_;

    return {
        (map { $_ => $row->$_ } qw/id/),
    };
}

# filtro por nota
# filtro por projeto [ímplicito]
# filtro por categoria
# ordem por distancia (pegar lat long)
# filtro por nome (generico)

sub ponto_apoio_list {
    my ($c, %opts) = @_;

    my $user_obj     = $opts{user_obj};
    my $latitude     = $opts{latitude} or confess 'missing latitude';
    my $longitude    = $opts{longitude} or confess 'missing longitude';
    my $keywords     = trim(lc($opts{keywords} || ''));
    my $max_distance = $opts{max_distance} || 50;
    my $categorias   = $opts{categorias};

    my $eh_24h             = $opts{eh_24h};
    my $dias_funcionamento = $opts{dias_funcionamento};

    confess '$categorias is not arrayref' if $categorias && ref $categorias ne 'ARRAY';

    $c->reply_invalid_param('Distância precisa ser menor que 50km', 'form_error', 'max_distance')
      if $max_distance > 50;
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
    $rows = 100 if !is_test() && ($rows > 5000 || $rows < 100);

    if ($opts{as_csv}) {
        $rows = -1;
    }

    # just in case, pra nao rolar sql injection, mas aqui já deve ter validado isso no controller
    confess '$latitude is not valid'  unless $latitude  =~ /^(([-+]?(([1-8]?\d(\.\d+))+|90)))$/ao;
    confess '$longitude is not valid' unless $longitude =~ /^([-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?))$/ao;

    # essa conta aqui só é uma aproximação do globo, com distorções nos polos e equador
    # o ideal é fazer isso tudo no postgres, com postgis, pois lá o suporte a index é bem mais simples
    # mas o chato é manter as bases sincronizadas (pelo menos lat/long+categorias+textos indexados)
    # se você é acredita que a terra é plana, pode ignorar o comentario acima, *ta tudo bem*
    my $distance_in_km = qq| 111.111 * DEGREES(ACOS(LEAST(1.0, COS(RADIANS(me.latitude))
     * COS(RADIANS( $latitude ))
     * COS(RADIANS(me.longitude - $longitude))
     + SIN(RADIANS(me.latitude))
     * SIN(RADIANS( $latitude ))))) AS distance_in_km|;

    my $rs = $c->schema2->resultset('PontoApoio')->search(
        {
            'me.test_status'             => is_test() ? 'test' : 'prod',
            'me.ja_passou_por_moderacao' => 1,
            'me.status'                  => 'active',

            ($categorias ? ('me.categoria' => {in => $categorias}) : ()),
        },
        {
            'columns' => [
                {distance_in_km => \$distance_in_km},
                {categoria_nome => 'categoria.label'},
                {categoria_cor  => 'categoria.color'},,
                {categoria_id   => 'categoria.id'},
                {categoria_id   => 'categoria.id'},
                ($user_obj ? ({cliente_avaliacao => 'cliente_ponto_apoio_avaliacaos.avaliacao'}) : ()),
                qw/me.id me.nome me.latitude me.longitude me.avaliacao me.uf me.qtde_avaliacao/,
            ],
            join => [
                'categoria',
                ($user_obj ? ('cliente_ponto_apoio_avaliacaos') : ()),
            ],

            order_by     => \'distance_in_km ASC',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',

            (
                $rows = -1 ? () : (
                    having => [\['distance_in_km < ?', $max_distance + 1]],
                    rows   => $rows + 1,
                    offset => $offset,
                )
            )
        }
    );

    if ($keywords) {
        $rs = $rs->search(
            {
                '-or' => [
                    \['lower(me.nome) like ?',      "$keywords%"],
                    \['lower(me.sigla) like ?',     "$keywords%"],
                    \['lower(me.descricao) like ?', "%$keywords%"],
                ],
            }
        );
    }

    $rs = $rs->search({'eh_24h'             => $eh_24h ? 1 : 0})     if defined $eh_24h;
    $rs = $rs->search({'dias_funcionamento' => $dias_funcionamento}) if $dias_funcionamento;

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
        $_->{distancia} = int(delete $_->{distance_in_km}) . '';
        $_->{categoria} = {
            id   => delete $_->{categoria_id},
            cor  => delete $_->{categoria_cor},
            nome => delete $_->{categoria_nome},
        };
    }

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
                name => (exists $names{$item->[0]} ? $names{$item->[0]} : &_gen_name_from_code($item->[0])),
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

    return {
        success => 1,
        message => 'Sua sugestão será avaliada antes de ser publicada.',
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
    $c->reply_invalid_param('ponto de apoio não encontrado', 'form_error', 'ponto_apoio_id') unless $ponto_apoio;

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
                    columns      => [{avaliacao => \'coalesce( avg(avaliacao), 0)', qtde_avaliacao => \'count(1)'}],
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
            'me.test_status'             => is_test() ? 'test' : 'prod',
            'me.ja_passou_por_moderacao' => 1,
            'me.status'                  => 'active',
            'me.id'                      => $id,
        },
        {
            'columns' => [
                {categoria_nome => 'categoria.label'},
                {categoria_cor  => 'categoria.color'},,
                {categoria_id   => 'categoria.id'},
                {categoria_id   => 'categoria.id'},
                ($user_obj ? ({cliente_avaliacao => 'cliente_ponto_apoio_avaliacaos.avaliacao'}) : ()),
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
                  me.eh_24h
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
        publico          => 'Público',
        privado_coletivo => 'Privado coletivo',
        privado_ong      => 'Privado ONG',
    };
    $row->{natureza} = $natureza_de_para->{$row->{natureza}} || $row->{natureza};


    my $dow_de_para = {
        dias_uteis             => 'Dias úteis',
        fds                    => 'Fim de semana',
        dias_uteis_fds_plantao => 'Dias úteis com plantão aos fins de semanas',
        todos_os_dias          => 'Todos os dias'
    };
    $row->{dias_funcionamento} = $dow_de_para->{$row->{dias_funcionamento}} || $row->{dias_funcionamento};


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

1;
