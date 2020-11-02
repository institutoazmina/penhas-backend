package Penhas::Controller::Logout;
use Mojo::Base 'Penhas::Controller';
use Penhas::KeyValueStorage;

sub logout_post {
    my $c = shift;

    my $session_id        = $c->stash('jwt_session_id');
    my $session_cache_key = $c->stash('session_cache_key');
    Penhas::KeyValueStorage->instance->redis->del($ENV{REDIS_NS} . $session_cache_key) if $session_cache_key;

    $c->schema2->resultset('ClientesActiveSession')->search({id => $session_id})->delete;

    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
