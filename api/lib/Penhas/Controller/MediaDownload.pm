package Penhas::Controller::MediaDownload;
use Mojo::Base 'Penhas::Controller';
use Digest::MD5 qw/md5_hex/;
use DateTime;
use Penhas::Types qw/TweetID/;

sub ensure_user_loaded {
    my $c = shift;

    die 'missing user' unless $c->stash('user');
    return 1;
}

sub get_media {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        'm' => {required => 1, type => 'Str', max_length => 36, min_length => 36,},
        'h' => {required => 1, type => 'Str', max_length => 6,  min_length => 6},
        'q' => {required => 1, type => 'Str', max_length => 2,  min_length => 2},
    );

    my $user    = $c->stash('user');
    my $quality = $params->{q};
    my $ip      = $c->remote_addr;

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . $user->{id} . $quality . $ip), 0, 6);

    if ($params->{h} ne $hash) {
        return $c->render(
            json => {
                error   => 'media_hash_invalid',
                message => 'hash não confere.'
            },
            status => 400,
        );
    }


    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
