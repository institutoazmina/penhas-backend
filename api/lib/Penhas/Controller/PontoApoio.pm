package Penhas::Controller::PontoApoio;
use Mojo::Base 'Penhas::Controller';
use utf8;

use DateTime;
use Penhas::Logger;
use Penhas::Utils qw/is_test/;
use MooseX::Types::Email qw/EmailAddress/;
use Penhas::Types qw/Latitute Longitude IntList/;
use Penhas::Controller::Me;
use JSON;

use DateTime::Format::Pg;

# usado pelo chatbot do twitter
sub pa_list_unlimited {
    my $c = shift;

    my $valid = $c->validate_request_params(
        token => {required => 1, type => 'Str', max_length => 100,},
    );

    if ($ENV{PONTO_APOIO_SECRET} && $valid->{token} && $valid->{token} eq $ENV{PONTO_APOIO_SECRET}) {

        my $valid = $c->validate_request_params(
            latitude     => {max_length => 20, required => 1, type => Latitute},
            longitude    => {max_length => 20, required => 1, type => Longitude},
            max_distance => {max_length => 20, required => 1, type => 'Int'},
            rows         => {max_length => 20, required => 1, type => 'Int'},
        );

        my $ponto_apoio_list = $c->ponto_apoio_list(
            %$valid,
            all_columns => 1,
        );

        return $c->render(
            json   => $ponto_apoio_list,
            status => 200,
        );

    }

    return $c->reply_invalid_param('invalid token', 'token_invalid', 'token');
}

sub pa_list {
    my $c = shift;

    # limite de requests por segundo no IP
    # no maximo 30 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'pa_list:' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(30, 60);

    return &_pa_list($c);
}

sub user_pa_list {
    my $c = shift;

    die 'missing user' unless $c->stash('user_obj');

    # limite de requests por usuario
    # no maximo 10 request por minuto
    $c->stash(apply_rps_on => 'pa_list:' . $c->stash('user_id'));
    $c->apply_request_per_second_limit(10, 60);

    return &_pa_list($c);
}

sub _pa_list {
    my $c = shift;

    my $valid = $c->validate_request_params(
        debug          => {required   => 0,    type     => 'Int'},
        categorias     => {required   => 0,    type     => IntList},
        projeto        => {max_length => 200,  required => 0, type => 'Str'},
        rows           => {required   => 0,    type     => 'Int'},
        max_distance   => {required   => 0,    type     => 'Int'},
        next_page      => {max_length => 9999, required => 0, type => 'Str'},
        location_token => {max_length => 9999, required => 0, type => 'Str'},
        keywords       => {max_length => 200,  required => 0, type => 'Str'},

        is_web             => {required => 0, type => 'Bool', undef_if_missing => 1},
        full_list          => {required => 0, type => 'Bool', undef_if_missing => 1},
        eh_24h             => {required => 0, type => 'Bool', undef_if_missing => 1},
        dias_funcionamento => {required => 0, type => 'Str',  max_length       => 99},
        as_csv             => {required => 0, type => 'Bool', undef_if_missing => 1},
    );

    my $debug    = '';
    my $user_obj = $c->stash('user_obj');

    if ($valid->{location_token}) {
        $debug .= 'location_token was defined' . "\n";
        log_debug("location_token setting lat/long");

        my $tmp = eval { $c->decode_jwt($valid->{location_token}) };
        $c->reply_invalid_param('location_token')
          if ($tmp->{iss} || '') ne 'LT';

        log_debug("location_token => " . $valid->{location_token});
        ($valid->{latitude}, $valid->{longitude}) = split /,/, $tmp->{latlng};

        log_debug('valid after split => ' . to_json($valid));

        $debug .= 'valid after split => ' . to_json($valid) . "\n";
    }


    if (!(defined $valid->{latitude} && defined $valid->{longitude})) {

        my $gps_required = $user_obj ? 0 : 1;
        $gps_required = 0 if $valid->{is_web} || $valid->{as_csv};
        log_debug('no lat/lng, this is required if is is_web or as_csv is not set => ' . $gps_required);

        $debug .= 'no lat/lng, this is required if is is_web or as_csv is not set => ' . $gps_required . "\n";

        $c->merge_validate_request_params(
            $valid,
            latitude  => {max_length => 20, required => $gps_required, type => Latitute},
            longitude => {max_length => 20, required => $gps_required, type => Longitude},
        );
        log_debug('valid after merge => ' . to_json($valid));
        $debug .= 'valid after merge => ' . to_json($valid) . "\n";
    }
    else {
        log_debug('no lat/lng position yet => ' . to_json($valid));
        $debug .= 'no lat/lng position yet => ' . to_json($valid) . "\n";
    }

    # se nao tem ainda, eh pq o usuario nao mandou, entao temos que pegar via CEP
    if ((!$valid->{latitude} || !$valid->{longitude})
        && !($valid->{is_web} || $valid->{as_csv}))
    {
        log_debug('!lat or !lng && ! is_web or is_csv');
        $debug .= '!lat or !lng && ! is_web or is_csv' . "\n";

        if (!$user_obj) {
            $c->reply_invalid_param('é necessário localização', 'location_token');
        }

        die 'user_obj should be defined' unless $user_obj;

        ($valid->{latitude}, $valid->{longitude}) = $c->geo_code_cached_by_user($user_obj);

        log_debug('lat/long was overwritten by user geocode');
        $debug .= 'lat/long was overwritten by user geocode' . "\n";
    }

    $valid->{categorias} = [split /,/, $valid->{categorias}] if $valid->{categorias};

    my $ponto_apoio_list = $c->ponto_apoio_list(
        %$valid,
        user_obj => $user_obj,
    );
    if (exists $ponto_apoio_list->{file}) {
        return $c->render_file(
            'filepath' => $ponto_apoio_list->{file},
            'filename' => 'lista-pontos-apoios-' . DateTime->now->set_time_zone('America/Sao_Paulo')->dmy('-') . '.csv',
        );
    }

    if ($valid->{debug} == 1) {
        $ponto_apoio_list->{_debug}        = $debug;
        $ponto_apoio_list->{_debug_params} = $valid;
    }

    $c->render(
        json   => $ponto_apoio_list,
        status => 200,
    );
}

sub pa_aux_data {
    my $c = shift;

    my $valid = $c->validate_request_params(
        projeto => {required => 0, type => 'Str', max_length => 100},
    );

    # limite de requests por segundo no IP
    # no maximo 30 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'pad:' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(30, 60);

    my $filter_projeto_id = $c->_project_id_by_label($valid->{projeto} ? (projeto => $valid->{projeto}) : ());

    $c->render(
        json => {
            projetos => (
                $filter_projeto_id ? [] : [
                    $c->schema2->resultset('PontoApoioProjeto')->search(
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
            ),
            categorias => [
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
            ],
            dias_funcionamento => [
                {value => 'dias_uteis',             label => 'Dias úteis'},
                {value => 'fds',                    label => 'Fim de semana'},
                {value => 'dias_uteis_fds_plantao', label => 'Dias úteis com plantão aos fins de semanas'},
                {value => 'todos_os_dias',          label => 'Todos os dias'},
            ],
            fields => $c->ponto_apoio_fields(
                format            => 'public',
                filter_projeto_id => $filter_projeto_id,
            ),
        },
        status => 200,
    );
}

sub user_pa_suggest {
    my $c = shift;

    $c->reply_invalid_param('Por favor, atualize o aplicativo para enviar sugestões de ponto de apoio',
        'endereco_ou_cep');

    die 'missing user' unless $c->stash('user_obj');

    # limite de requests por usuario
    # no maximo 120 request por hora
    $c->stash(apply_rps_on => 'pa_suggest:' . $c->stash('user_id'));
    $c->apply_request_per_second_limit(120, 60 * 60);

    my $rules = $c->ponto_apoio_fields(format => 'rules');
    my $valid = $c->validate_request_params(@$rules);

    $c->render(
        json => $c->ponto_apoio_suggest(
            fields   => $valid,
            user_obj => $c->stash('user_obj'),
        ),

        status => 200,
    );
}

sub user_pa_suggest_full {
    my $c = shift;

    die 'missing user' unless $c->stash('user_obj');

    # limite de requests por usuario
    # no maximo 120 request por hora
    $c->stash(apply_rps_on => 'pa_suggest:' . $c->stash('user_id'));
    $c->apply_request_per_second_limit(120, 60 * 60);

    my $rules = $c->ponto_apoio_fields_v2(format => 'rules');
    use DDP;
    p $rules;

    my $valid = $c->validate_request_params(@$rules);

    for (qw/ddd1 ddd2 telefone1 telefone2/) {
        delete $valid->{$_} if exists $valid->{$_} && $valid->{$_} eq '';
    }

    if (defined $valid->{eh_24h}) {
        $valid->{eh_24h} = $valid->{eh_24h} eq 'Sim' ? 1 : 0;
    }

    if (defined $valid->{has_whatsapp}) {
        $valid->{has_whatsapp} = $valid->{has_whatsapp} eq 'Sim' ? 1 : 0;
    }

    if (defined $valid->{cep}) {
        $valid->{cep} =~ s/[^0-9]//a;
    }

    $c->render(
        json => $c->ponto_apoio_suggest(
            v2       => 1,
            fields   => $valid,
            user_obj => $c->stash('user_obj'),
        ),

        status => 200,
    );
}

sub user_pa_rating {
    my $c = shift;

    die 'missing user' unless $c->stash('user_obj');

    # limite de requests por usuario
    # no maximo 120 request por hora
    $c->stash(apply_rps_on => 'pa_rating:' . $c->stash('user_id'));
    $c->apply_request_per_second_limit(120, 60 * 60);


    my $valid = $c->validate_request_params(
        remove         => {required => 0, type => 'Str', max_length => 1},
        ponto_apoio_id => {required => 1, type => 'Int'},
    );

    if (!$valid->{remove}) {
        $c->merge_validate_request_params(
            $valid,
            rating => {required => 1, type => 'Int', max_length => 2},
        );
    }
    $c->ponto_apoio_rating(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    $c->render(text => '', status => 204,);
}

sub user_geocode {
    my $c = shift;

    die 'missing user' unless $c->stash('user_obj');

    # limite de requests por usuario
    $c->stash(apply_rps_on => 'daily_geocode:' . $c->stash('user_id'));
    $c->apply_request_per_second_limit(1000, 60 * 60 * 24);

    # no maximo 20 request por hora
    $c->stash(apply_rps_on => 'hourly_geocode:' . $c->stash('user_id'));
    $c->apply_request_per_second_limit(200, 60 * 60);

    return &_geocode($c);
}

sub public_geocode {
    my $c = shift;

    my $remote_ip = substr($c->remote_addr(), 0, 18);

    $c->stash(apply_rps_on => 'daily_geocode:' . $remote_ip);
    $c->apply_request_per_second_limit(1000, 60 * 60 * 24);

    $c->stash(apply_rps_on => 'hourly_geocode:' . $remote_ip);
    $c->apply_request_per_second_limit(200, 60 * 60);

    return &_geocode($c);
}

sub _geocode {
    my $c = shift;

    my $valid = $c->validate_request_params(
        address => {required => 0, type => 'Str', max_length => 200},
    );

    my $latlng = $c->geo_code_cached($valid->{address});

    if (!$latlng) {
        $c->reply_invalid_param('Localização não encontrada!', 'location_not_found', 'address');
    }
    else {
        my $location_token = $c->encode_jwt(
            {
                iss    => 'LT',
                latlng => $latlng,
            },
            1
        );

        my $label = $c->reverse_geo_code_cached($latlng);

        $c->render(
            json => {
                location_token => $location_token,
                label          => $label
            },
            status => 200,
        );
    }
}


sub user_pa_detail {
    my $c = shift;
    die 'missing user' unless $c->stash('user_obj');

    $c->render(
        json => $c->ponto_apoio_detail(
            id       => $c->stash('ponto_apoio_id'),
            user_obj => $c->stash('user_obj')
        ),
        status => 200,
    );
}

sub public_pa_detail {
    my $c = shift;

    my $remote_ip = substr($c->remote_addr(), 0, 18);

    $c->stash(apply_rps_on => 'pa:' . $remote_ip);
    $c->apply_request_per_second_limit(120, 60);

    $c->stash(apply_rps_on => 'hpa:' . $remote_ip);
    $c->apply_request_per_second_limit(1000, 60 * 60);

    $c->render(
        json   => $c->ponto_apoio_detail(id => $c->stash('ponto_apoio_id')),
        status => 200,
    );
}


1;
