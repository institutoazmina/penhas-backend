package Penhas::Controller::MediaDownload;
use Mojo::Base 'Penhas::Controller';
use Digest::MD5 qw/md5_hex/;
use DateTime;
use Penhas::Utils qw/get_media_filepath is_uuid_v4 is_test/;
use Mojo::UserAgent;
use feature 'state';
use Encode;

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user_id');
    return 1;
}

sub logged_in_get_media {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        'm' => {required => 1, type => 'Str', max_length => 36, min_length => 36,},
        'h' => {required => 1, type => 'Str', max_length => 12, min_length => 12},
        'q' => {required => 1, type => 'Str', max_length => 2,  min_length => 2},
    );

    my $id = $params->{m};

    my $user_id = $c->stash('user_id');
    my $quality = $params->{q};
    my $ip      = $c->remote_addr;

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . $user_id . $quality . $ip), 0, 12);

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

# download de photos com cache+proxy pra sempre ser https
sub public_get_proxy {
    my $c = shift;

    # limite bem generoso por IP, 180x por minuto [3 loads a cada 10 segundos, repetindo por 1 minuto]
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(180, 60);

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        'href' => {required => 1, type => 'Str', max_length => 5000, min_length => 5,},
        'h'    => {required => 1, type => 'Str', max_length => 12,   min_length => 12},
    );

    my $href = $params->{href};

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . encode_utf8($href)), 0, 12);

    if ($params->{h} ne $hash) {
        return $c->render(
            json => {
                error   => 'media_hash_invalid',
                message => 'hash não confere.'
            },
            status => 400,
        );
    }

    my $cached_filename = get_media_filepath('NT' . md5_hex(encode_utf8($href)));

    if (-e $cached_filename) {
        $c->reply->file($cached_filename);
    }
    else {
        state $ua = Mojo::UserAgent->new;

        $c->render_later;
        $ua->get_p($href)->then(
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
