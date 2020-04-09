package Penhas::Controller::Logout;
use Mojo::Base 'Penhas::Controller';

sub post {
    my $c = shift;

    my $mastodon_session = $c->schema->resultset('OauthAccessToken')->find($c->stash('mastodon_oauth_id'));
    $mastodon_session->delete if $mastodon_session;

    $c->directus->delete(table => 'clientes_active_sessions', id => $c->stash('jwt_session_id'));

    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
