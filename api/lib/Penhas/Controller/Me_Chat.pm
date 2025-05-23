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
        rows       => {required => 0, type => 'Int'},
        cliente_id => {required => 0, type => 'Int',},
        next_page  => {required => 0, type => 'Str', max_length => 9999},
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
        cliente_id => {required => 1, type => 'Int'},
        prefetch   => {required => 0, type => 'Bool'},
    );

    my $ret = $c->chat_open_session(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

sub me_delete_session {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        chat_auth => {required => 1, type => 'Str', max_length => 9999},
    );

    if ($valid->{chat_auth} !~ /\./) {
        $c->support_clear_messages(
            %$valid,
            user_obj => $c->stash('user_obj'),
        );
    }
    else {
        $c->chat_delete_session(
            %$valid,
            user_obj => $c->stash('user_obj'),
        );
    }

    return $c->render(
        text   => '',
        status => 204,
    );

}

sub me_send_message {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        chat_auth => {required => 1, type => 'Str', max_length => 9999},
        message   => {required => 1, type => 'Str', max_length => 9999},
    );

    my $ret;
    if ($valid->{chat_auth} !~ /\./) {
        $ret = $c->support_send_message(
            %$valid,
            user_obj => $c->stash('user_obj'),
        );
    }
    else {
        $ret = $c->chat_send_message(
            %$valid,
            user_obj => $c->stash('user_obj'),
        );
    }

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

sub me_list_message {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        chat_auth  => {required => 1, type => 'Str', max_length => 9999},
        pagination => {required => 0, type => 'Str', max_length => 9999},
        rows       => {required => 0, type => 'Int'},
    );

    my $ret;
    if ($valid->{chat_auth} !~ /\./) {
        $ret = $c->support_list_message(
            %$valid,
            user_obj => $c->stash('user_obj'),
        );
    }
    else {
        $ret = $c->chat_list_message(
            %$valid,
            user_obj => $c->stash('user_obj'),
        );
    }

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

sub me_manage_blocks {
    my $c        = shift;
    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        cliente_id => {required => 1, type => 'Int'},
        block      => {required => 1, type => 'Bool'},
    );

    $c->chat_manage_block(
        %$valid,
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
