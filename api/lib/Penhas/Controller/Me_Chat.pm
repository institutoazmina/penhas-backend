package Penhas::Controller::Me_Chat;
use Mojo::Base 'Penhas::Controller';

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
        rows      => {required => 0, type => 'Int'},
        next_page => {required => 0, type => 'Str', max_length => 9999},
        name      => {required => 0, type => 'Str', max_length => 100, min_length => 2},
    );

    ...;
}

1;
