package Penhas::Controller::Me_Tweets;
use Mojo::Base 'Penhas::Controller';

use DateTime;
use Penhas::Types qw/TweetID/;

sub ensure_user_loaded {
    my $c = shift;

    die 'missing user' unless $c->stash('user');
    return 1;
}

sub add {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        content   => {required => 1, type => 'Str', max_length => $ENV{TWEET_CONTENT_MAX_LENGTH} || 2200},
        media_ids => {required => 0, type => 'Str', max_length => 500},
    );
    my $user = $c->stash('user');

    my $tweet = $c->add_tweet(
        user      => $user,
        content   => $params->{content},
        media_ids => $params->{media_ids},
        reply_to  => $c->stash('reply_to'),
    );

    return $c->render(
        json   => $tweet,
        status => 200,
    );
}

sub delete {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        id => {required => 1, type => TweetID},
    );

    my $user = $c->stash('user');

    $c->delete_tweet(
        user => $user,
        id   => $params->{id}
    );

    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
