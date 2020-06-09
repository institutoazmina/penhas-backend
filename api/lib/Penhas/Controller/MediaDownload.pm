package Penhas::Controller::MediaDownload;
use Mojo::Base 'Penhas::Controller';
use Digest::MD5 qw/md5_hex/;
use DateTime;
use Penhas::Utils qw/get_media_filepath is_uuid_v4 is_test/;
use Mojo::UserAgent;
use feature 'state';

sub ensure_user_loaded {
    my $c = shift;

    die 'missing user' unless $c->stash('user_id');
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

    my $id = $params->{m};

    my $user_id = $c->stash('user_id');
    my $quality = $params->{q};
    my $ip      = $c->remote_addr;

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . $user_id . $quality . $ip), 0, 6);

    if ($params->{h} ne $hash) {
        return $c->render(
            json => {
                error   => 'media_hash_invalid',
                message => 'hash não confere.'
            },
            status => 400,
        );
    }

    # just in case
    $c->reply_item_not_found() unless is_uuid_v4($id);

    my $cached_filename = get_media_filepath("$id.$quality");

    if (is_test()) {
        return $c->render(json => {media_id => $id, quality => $quality});
    }

    if (-e $cached_filename) {
        $c->reply->file($cached_filename);
    }
    else {
        state $ua = Mojo::UserAgent->new;

        my $media             = $c->schema2->resultset('MediaUpload')->find($id) or $c->reply_item_not_found();
        my $resolution_column = $quality eq 'sd' ? 's3_path_avatar' : 's3_path';
        my $s3_path           = $media->$resolution_column;

        $c->render_later;
        $ua->get_p($s3_path)->then(
            sub {
                my $tx = shift;

                $tx->result->save_to($cached_filename);

                $c->reply->file($cached_filename);

            }
        )->catch(
            sub {
                my $err = shift;
                $c->log->debug("Proxy error: $err");
                $c->render(text => 'Something went wrong!', status => 400);
            }
        );

    }

}

1;
