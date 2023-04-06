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
            titulo         => {required => 0, type => 'Str', max_length => 512,},
            descricao      => {required => 0, type => 'Str', max_length => 2048,},
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

1;
