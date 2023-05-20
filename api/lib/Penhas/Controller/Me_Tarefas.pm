package Penhas::Controller::Me_Tarefas;
use Mojo::Base 'Penhas::Controller';

use DateTime;
use Penhas::Types qw/TweetID/;

sub assert_user_perms {
    my $c = shift;

    $c->assert_user_has_module('tweets');
    return 1;
}

sub list {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    my $valid  = $c->validate_request_params(
        modificado_apos => {required => 1, type => 'Int'},
    );

    my $result = $c->cliente_lista_tarefas(
        user_obj => $c->stash('user_obj'),
        %$valid,
    );

    return $c->render(
        json   => $result,
        status => 200,
    );
}

sub sync {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    my $valid;
    if ($params->{remove}) {
        $valid = $c->validate_request_params(
            id     => {required => 1, type => 'Int'},
            remove => {required => 1, type => 'Bool'},
        );
    }
    else {
        $valid = $c->validate_request_params(
            id             => {required => 1, type => 'Int'},
            checkbox_feito => {required => 1, type => 'Bool'},
            campo_livre_1  => {required => 0, type => 'Str', max_length => 512, empty_is_valid => 1},
            campo_livre_2  => {required => 0, type => 'Str', max_length => 512, empty_is_valid => 1},
            campo_livre_3  => {required => 0, type => 'Str', max_length => 512, empty_is_valid => 1},
        );
    }

    my $result = $c->cliente_sync_lista_tarefas(
        user_obj => $c->stash('user_obj'),
        %$valid,
    );

    return $c->render(
        json   => $result,
        status => 200,
    );
}

sub nova {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    my $valid = $c->validate_request_params(
        titulo    => {required => 1, type => 'Str', max_length => 512,  min_length => 1,},
        descricao => {required => 1, type => 'Str', max_length => 2048, min_length => 1},
        agrupador => {required => 1, type => 'Str', max_length => 120,  min_length => 1},
        token     => {required => 1, type => 'Str', max_length => 120,  min_length => 1},

        # ta aqui pq o retorno dele é o mesmo que o list
        # mas como nao vai ser usado no app, nem faz tanto sentido mais
        modificado_apos => {required => 1, type => 'Int'},
    );

    my $result = $c->cliente_nova_tarefas(
        user_obj => $c->stash('user_obj'),
        %$valid,
    );

    return $c->render(
        json   => $result,
        status => 200,
    );
}


1;
