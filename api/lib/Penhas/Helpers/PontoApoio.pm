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

    my $latitude  = $opts{latitude}  or confess 'missing latitude';
    my $longitude = $opts{longitude} or confess 'missing longitude';
    my $keywords  = trim(lc($opts{keywords}));

    # just in case, pra nao rolar sql injection, mas aqui já deve ter validado isso no controller
    confess '$latitude is not valid'  unless $latitude  =~ /^(([-+]?(([1-8]?\d(\.\d+))+|90)))$/ao;
    confess '$longitude is not valid' unless $longitude =~ /^([-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?))$/ao;

    # essa conta aqui só é uma aproximação do globo, com distorções nos polos e equador
    # o ideal é fazer isso tudo no postgres, com postgis, pois lá o suporte a index é bem mais simples
    # mas o chato é manter as bases sincronizadas (pelo menos lat/long+categorias+textos indexados)
    # se você é acredita que a terra é plana, pode ignorar o comentario acima, *ta tudo bem*
    my $distance_in_km = qq| 111.111 * DEGREES(ACOS(LEAST(1.0, COS(RADIANS(me.Latitude))
     * COS(RADIANS( $latitude ))
     * COS(RADIANS(me.Longitude - $longitude))
     + SIN(RADIANS(me.Latitude))
     * SIN(RADIANS( $latitude ))))) AS distance_in_km|;

    my $rs = $c->schema2->resultset('PontoApoio')->search(
        {
            'me.test_status' => is_test() ? 'test' : 'prod',
        },
        {
            '+columns' => [{distance_in_km => \$distance_in_km}],
            order_by   => \'distance_in_km ASC',
            rows => 100,
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

    my @results = $rs->all;

    use DDP; p @results;

    return {


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


1;
