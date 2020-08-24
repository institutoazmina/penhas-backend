package Penhas::Controller::Me_Chat;
use Mojo::Base 'Penhas::Controller';
use Penhas::Types qw/IntList/;
use DateTime;

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user');
    return 1;
}


sub me_chat_find_users {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        rows      => {required => 0, type => 'Int'},
        skills    => {required => 0, type => IntList},
        next_page => {required => 0, type => 'Str', max_length => 9999},
        name      => {required => 0, type => 'Str', max_length => 100, min_length => 2},
    );

    # só pode buscar outros usuários quem puder conversar com contas em privado
    $c->reply_invalid_param('Seu perfil não tem permissão para utilizar este recurso.')
      unless $user_obj->access_modules_str =~ /,chat_privado,/;

    my $ret = $c->chat_find_users(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

sub me_chat_sessions {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        rows => {required => 0, type => 'Int'},
        next_page => {required => 0, type => 'Str', max_length => 9999},
    );

    my $ret = $c->chat_list_sessions(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

sub me_open_session {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        cliente_id => {required => 1, type => 'Str', max_length => 12},
    );
    if ($valid->{cliente_id} ne 'support') {
        $c->merge_validate_request_params(
            $valid,
            cliente_id => {required => 1, type => 'Int'},
        );
    }

    my $ret = $c->chat_open_session(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

sub me_load_profile {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    # só pode buscar outros usuários quem puder conversar com contas em privado
    $c->reply_invalid_param('Seu perfil não tem permissão para utilizar este recurso.')
      unless $user_obj->access_modules_str =~ /,chat_privado,/;

    my $valid = $c->validate_request_params(
        cliente_id => {required => 1, type => 'Int'},
    );

    my $ret = $c->chat_profile_user(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

1;
