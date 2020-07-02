package Penhas::Controller::Me_Guardioes;
use Mojo::Base 'Penhas::Controller';

use DateTime;
use Penhas::Types qw/MobileNumber/;

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user');
    return 1;
}

my @commonfields = (
    apelido => {required => 1, type => 'Str', max_length => 200},
    nome    => {required => 1, type => 'Str', max_length => 200},
);

sub upsert {
    my $c = shift;

    my $valid = $c->validate_request_params(
        celular => {required => 1, type => 'Str'},
        @commonfields,
    );

    return $c->render(
        json => $c->cliente_upsert_guardioes(
            %$valid,
            user => $c->stash('user'),
        ),
        status => 200,
    );
}

sub edit {
    my $c = shift;

    my $valid = $c->validate_request_params(
        id => {required => 1, type => 'Int'},
        @commonfields,
    );

    return $c->render(
        json => $c->cliente_edit_guardioes(
            %$valid,
            user => $c->stash('user'),
        ),
        status => 200,
    );
}

sub delete {
    my $c = shift;

use DDP; p $c;
    $c->cliente_delete_guardioes(
        id => $c->param('guard_id'),
        user => $c->stash('user'),
    );

    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
