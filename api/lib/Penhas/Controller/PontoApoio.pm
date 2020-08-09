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
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(30, 60);

    my $valid = $c->validate_request_params(
        next_page      => {max_length => 9999, required => 0, type => 'Str'},
        rows           => {required   => 0,    type     => 'Int'},
        location_token => {max_length => 9999, required => 0, type => 'Str'},
    );

    if ($valid->{location_token}){
        # TODO extrair o token pra lat/long
    }

    $c->merge_validate_request_params(
        $valid,
        latitude  => {max_length => 16, required => 1, type => Latitute},
        longitude => {max_length => 16, required => 1, type => Longitude},
    );

    my $ponto_apoio_list = $c->ponto_apoio_list(
        %$valid,
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
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
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

sub pa_suggest {
    my $c = shift;

    Penhas::Controller::Me::check_and_load($c);

    # limite de requests por segundo no IP
    # no maximo 120 request por hora
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
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

1;
