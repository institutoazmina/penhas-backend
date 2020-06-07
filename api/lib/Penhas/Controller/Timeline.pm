package Penhas::Controller::Timeline;
use Mojo::Base 'Penhas::Controller';

use DateTime;
use Penhas::Types qw/TweetID/;

sub ensure_user_loaded {
    my $c = shift;

    Penhas::Controller::Me::check_and_load($c);
    die 'missing user' unless $c->stash('user');
    return 1;
}

sub load_object {
    my $c = shift;

    die 'missing tweet_id' unless $c->param('tweet_id');
    my $tweet = $c->directus->search_one(
        table => 'tweets',
        form  => {
            'filter[id][eq]'                      => $c->param('tweet_id'),
            'filter[status][eq]'                  => 'published',
            'filter[cliente_id.login_status][eq]' => 'OK',
        }
    );

    $c->reply_item_not_found() unless $tweet;
    $c->stash('tweet' => $tweet);
    return 1;
}

sub add_like {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        remove => {required => 0, type => 'Str', max_length => 1},
    );

    my $tweet = $c->like_tweet(
        id     => $c->stash('tweet')->{id},
        user   => $c->stash('user'),
        remove => exists $params->{remove} && $params->{remove} eq '1' ? 1 : 0,
    );

    return $c->render(
        json   => $tweet,
        status => 200,
    );
}

sub add_comment {
    my $c = shift;

    $c->stash('reply_to', $c->stash('tweet')->{id});
    return Penhas::Controller::Me_Tweets::add($c);
}

sub add_report {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        reason => {required => 1, type => 'Str', max_length => 500},
    );

    my $tweet = $c->report_tweet(
        id     => $c->stash('tweet')->{id},
        user   => $c->stash('user'),
        reason => $params->{reason}
    );

    return $c->render(
        json   => {message => 'Report enviado'},
        status => 200,
    );
}


sub list {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        rows        => {required => 0, type => 'Int'},
        after       => {required => 0, type => TweetID},
        before      => {required => 0, type => TweetID},
        parent_id   => {required => 0, type => TweetID},
        skip_myself => {required => 0, type => 'Int'},
        only_myself => {required => 0, type => 'Int'},
    );

    my $tweets = $c->list_tweets(
        %$params,
        user => $c->stash('user'),
    );

    return $c->render(
        json   => $tweets,
        status => 200,
    );
}


1;
