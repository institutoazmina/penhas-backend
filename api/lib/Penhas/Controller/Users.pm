package Penhas::Controller::Users;
use Mojo::Base 'Penhas::Controller';

use DateTime;

sub check_and_load {
    my $c = shift;

    my $user_id = $c->param('id');
    return $c->reply_forbidden() if $user_id != $c->stash('user_id');

    $c->stash(user => $c->schema->resultset('User')->find($user_id));
}

sub read {
    my $c = shift;

    my $user = $c->stash('user');

    return $c->render(json => {user => $user->build_row()}, status => 200,);
}

sub update {
    my $c = shift;

    #my $user = $c->stash('user')->execute($c, for => 'update', with => $c->req->params->to_hash);

    return $c->render(json => {id => $user->id}, status => 202,);
}

1;
