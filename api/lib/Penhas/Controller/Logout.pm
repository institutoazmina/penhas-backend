package Penhas::Controller::Logout;
use Mojo::Base 'Penhas::Controller';

sub post {
    my $c = shift;

    $c->schema2->resultset('ClientesActiveSession')->search({id => $c->stash('jwt_session_id')})->delete;

    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
