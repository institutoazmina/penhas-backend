package Penhas::Controller::Me_Tweets;
use Mojo::Base 'Penhas::Controller';

use DateTime;

sub ensure_user_loaded {
    my $c = shift;

    die 'missing user' unless $c->stash('user');
    return 1;
}

sub process {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        content => {required => 1, type => 'Str', max_length => 500},
    );
    my $session_id = delete $params->{session_id};

    my $user = $c->stash('user');

    my $tweet = $c->add_tweet(
        user    => $user,
        content => $params->{content}
    );
    use DDP; p $tweet;

    return $c->render(
        json => {
            id         => $tweet->{id},
            created_at => $tweet->{created_at}
        },
        status => 200,
    );
}

1;
