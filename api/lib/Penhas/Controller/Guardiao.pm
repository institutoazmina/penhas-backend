package Penhas::Controller::Guardiao;
use Mojo::Base 'Penhas::Controller';

use DateTime;

sub apply_rps {
    my $c = shift;

    # limite de requests por segundo no IP
    # no maximo 100 request por hora
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(100, 3600);
}

sub get {
    my $c = shift;

    my $valid = $c->validate_request_params(
        token => {required => 1, type => 'Str', max_length => 100,},
    );

    return $c->render(
        json   => $c->guardiao_load_by_token(%$valid)->render_guardiao_public_data(),
        status => 200,
    );
}

sub post {
    my $c = shift;

    my $valid = $c->validate_request_params(
        token  => {required => 1, type => 'Str', max_length => 100,},
        action => {required => 1, type => 'Str', max_length => 100,},
    );

    return $c->render(
        json   => $c->guardiao_update_by_token(%$valid)->render_guardiao_public_data(),
        status => 200,
    );
}


1;
