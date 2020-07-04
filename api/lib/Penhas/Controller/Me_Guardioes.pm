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
    nome => {required => 1, type => 'Str', max_length => 200},
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
            user_obj => $c->stash('user_obj'),
        ),
        status => 200,
    );
}

sub edit {
    my $c = shift;

    my $valid = $c->validate_request_params(
        @commonfields,
    );

    return $c->render(
        json => $c->cliente_edit_guardioes(
            %$valid,
            id       => $c->stash('guard_id'),
            user_obj => $c->stash('user_obj'),
        ),
        status => 200,
    );
}

sub delete {
    my $c = shift;

    $c->cliente_delete_guardioes(
        id       => $c->stash('guard_id'),
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        text   => '',
        status => 204,
    );
}

sub list {
    my $c = shift;

    my $ret = $c->cliente_list_guardioes(
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

sub alert_guards {
    my $c = shift;

    my $valid = $c->validate_request_params(
        gps_lat  => {required => 0, type => 'Str', max_length => 100},
        gps_long => {required => 0, type => 'Str', max_length => 100},
    );

    my $ret = $c->cliente_alert_guards(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

1;
