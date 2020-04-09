package Penhas::Controller::Me;
use Mojo::Base 'Penhas::Controller';

use DateTime;

sub check_and_load {
    my $c = shift;

    die 'missing user_id' unless $c->stash('user_id');
    my $user = $c->directus->search_one(
        table => 'clientes',
        form  => {
            'filter[id][eq]'     => $c->stash('user_id'),
            'filter[status][eq]' => 'active',
        }
    );

    $c->reply_not_found() unless $user;
    $c->stash('user' => $user);
    return 1;
}

sub find {
    my $c = shift;

    my $user = $c->stash('user');
    my $mastodon_session;

    my $feminino = $user->{genero} eq 'Feminino';
    my $screen = 'timeline';


    if ($screen eq 'timeline' && $feminino) {
        $mastodon_session = $c->schema->resultset('OauthAccessToken')->find($c->stash('mastodon_oauth_id'));
        $mastodon_session = $mastodon_session->token if $mastodon_session;
    }

    return $c->render(
        json => {
            user_profile => {
                (map { $_ => $user->{$_} } (qw/email cep dt_nasc nome_completo genero minibio raca/)),
            },

            screen           => $screen,
            mastodon_session => $mastodon_session
        },
        status => 200,
    );
}

sub update {
    my $c = shift;


#    return $c->render(json => {id => $user->id}, status => 202,);
}


1;
