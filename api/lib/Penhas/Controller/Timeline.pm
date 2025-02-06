package Penhas::Controller::Timeline;
use Mojo::Base 'Penhas::Controller';
use Penhas::Controller::Me;
use DateTime;
use Penhas::Types qw/TweetID IntList TimelineCategory/;
use Penhas::Utils;

sub assert_user_perms {
    my $c = shift;

    Penhas::Controller::Me::check_and_load($c);
    die 'missing user' unless $c->stash('user');
    return 1;
}

sub load_object {
    my $c = shift;

    die 'missing tweet_id' unless $c->param('tweet_id');
    my $tweet = $c->schema2->resultset('Tweet')->search(
        {
            'me.id'          => $c->param('tweet_id'),
            'me.status'      => 'published',
            'cliente.status' => 'active',
        },
        {
            join         => 'cliente',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->next;

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
        id       => $c->stash('tweet')->{id},
        user_obj => $c->stash('user_obj'),
        remove   => exists $params->{remove} && $params->{remove} eq '1' ? 1 : 0,
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
        reason => {required => 1, type => 'Str', max_length => 200},    # ta 200 no banco! nao 500
    );

    my $tweet = $c->report_tweet(
        id       => $c->stash('tweet')->{id},
        user_obj => $c->stash('user_obj'),
        reason   => $params->{reason}
    );

    return $c->render(
        json   => {message => 'Sua denúncia foi recebida com sucesso.'},
        status => 200,
    );
}


sub list {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        rows      => {required => 0, type => 'Int'},
        after     => {required => 0, type => TweetID},
        before    => {required => 0, type => TweetID},
        parent_id => {required => 0, type => TweetID},
        id        => {required => 0, type => TweetID},
        tags      => {required => 0, type => IntList},
        next_page => {required => 0, type => 'Str', max_length => 10000},
        category  => {require  => 0, type => TimelineCategory}
    );

    if (defined $params->{next_page}) {
        $params->{next_page} = eval { $c->decode_jwt($params->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($params->{next_page}{iss} || '') ne 'next_page';
    }
    else {
        delete $params->{next_page};
    }

    my ($os, $version) = get_semver_numeric($c->req->headers->user_agent || '');

    my $is_legacy = is_legacy_app($os, $version);
    my $tweets    = $c->list_tweets(
        %$params,
        is_legacy => $is_legacy,
        os        => $os,
        user_obj  => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $tweets,
        status => 200,
    );
}


1;
