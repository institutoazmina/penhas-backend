package Penhas::Controller::PontoApoio;
use Mojo::Base 'Penhas::Controller';
use utf8;

use DateTime;
use Penhas::Logger;
use Penhas::Utils qw/is_test/;
use MooseX::Types::Email qw/EmailAddress/;
use Penhas::Types qw/Latitute Longitude/;
use Penhas::Controller::Me;

use DateTime::Format::Pg;

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
        rows           => {required   => 0,    type     => 'Int'},
        max_distance   => {required   => 0,    type     => 'Int'},
        next_page      => {max_length => 9999, required => 0, type => 'Str'},
        location_token => {max_length => 9999, required => 0, type => 'Str'},
        keywords       => {max_length => 200,  required => 0, type => 'Str'},
    );

    my $user_obj = $c->stash('user_obj');
    if ($valid->{location_token}) {

        # TODO extrair o token pra lat/long
    }

    my $gps_required = $user_obj ? 0 : 1;
    $c->merge_validate_request_params(
        $valid,
        latitude  => {max_length => 16, required => $gps_required, type => Latitute},
        longitude => {max_length => 16, required => $gps_required, type => Longitude},
    );

    # se nao tem ainda, eh pq o usuario nao mandou, entao temos que pegar via CEP
    if (!$valid->{latitude} || !$valid->{latitude}) {
        die 'user_obj should be defined' unless $user_obj;

        # TOOD extrair lat/long via CEP do usuario


    }

    my $ponto_apoio_list = $c->ponto_apoio_list(
        %$valid,
        user_obj => $user_obj,
    );

    $c->render(
        json   => $ponto_apoio_list,
        status => 200,
    );
}

sub pa_aux_data {
    my $c = shift;

    # limite de requests por segundo no IP
    # no maximo 30 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'pad:' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(30, 60);

    $c->render(
        json => {
            projetos => [
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
            ],
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
            fields => $c->ponto_apoio_fields(format => 'public'),
        },
        status => 200,
    );
}

sub user_pa_suggest {
    my $c = shift;

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

sub user_pa_rating {
    my $c = shift;

    die 'missing user' unless $c->stash('user_obj');

    # limite de requests por usuario
    # no maximo 120 request por hora
    $c->stash(apply_rps_on => 'pa_rating:' . $c->stash('user_id'));
    $c->apply_request_per_second_limit(120, 60 * 60);


    my $valid = $c->validate_request_params(
        remove         => {required => 0, type => 'Str', max_length => 1},
        rating         => {required => 1, type => 'Int', max_length => 2},
        ponto_apoio_id => {required => 1, type => 'Int'},
    );

    $c->ponto_apoio_rating(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    $c->render(text => '', status => 204,);
}

1;
