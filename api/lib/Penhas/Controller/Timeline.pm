package Penhas::Controller::Timeline;
use Mojo::Base 'Penhas::Controller';

use DateTime;
use Penhas::Types qw/TweetID/;

sub ensure_user_loaded {
    my $c = shift;

    Penhas::Controller::Me::check_and_load($c);
use DDP; p "aa";
    die 'missing user' unless $c->stash('user');
    return 1;
}

sub load_object {
    my $c = shift;

    die 'missing tweet_id' unless $c->param('tweet_id');
    my $tweet = $c->directus->search_one(
        table => 'tweets',
        form  => {
            'filter[id][eq]'                   => $c->param('tweet_id'),
            'filter[status][eq]'               => 'published',
            'filter[cliente_id.login_status][eq]' => 'OK',
        }
    );
    use DDP; p $tweet;

    $c->reply_item_not_found() unless $tweet;
    $c->stash('tweet' => $tweet);
    return 1;
}

sub add_like {
    my $c = shift;
use DDP; p "Penhas::Controller::Timeline::add_like";
    my $tweet = $c->like_tweet(id => $c->stash('tweet')->{id}, user => $c->stash('user'));

    return $c->render(
        json   => { qtde_likes => $tweet->{qtde_likes} },
        status => 200,
    );
}


sub list {
    my $c = shift;


    return $c->render(
        json   => {},
        status => 200,
    );
}


1;
