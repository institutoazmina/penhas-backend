package Penhas::Controller::Logout;
use Mojo::Base 'Penhas::Controller';

sub post {
    my $c = shift;

    $c->directus->delete(table => 'clientes_active_sessions', id => $c->stash('jwt_session_id'));

    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
