package Penhas::Controller::News;
use Mojo::Base 'Penhas::Controller';
use Digest::MD5 qw/md5_hex/;
use DateTime;
use Penhas::Utils qw/get_media_filepath is_uuid_v4 is_test/;
use Mojo::UserAgent;
use feature 'state';

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user_id');
    return 1;
}

sub redirect {
    my $c = shift;

    # limite de requests por segundo no IP
    # no maximo 3 request a cada 10s
    # apenas pra proteger o banco, ja que esse eh um endpoint public
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'R' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(3, 10);

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        'uid' => {required => 1, type => 'Str', max_length => 9},                         # user id
        'nid' => {required => 1, type => 'Str', max_length => 9},                         # news id
        'u'   => {required => 1, type => 'Int', max_length => 20},                        # valid until
        't'   => {required => 1, type => 'Str', max_length => 20},                        # track id
        'h'   => {required => 1, type => 'Str', max_length => 12, min_length => 12},      # hash
        'url' => {required => 1, type => 'Str', max_length => 5000, min_length => 5,},    # redirect url
    );

    my $userid      = $params->{uid};
    my $newsid      = $params->{nid};
    my $trackid     = $params->{t};
    my $valid_until = $params->{u};
    my $url         = $params->{url};

    my $hash = substr(
        md5_hex(
            join ':', $ENV{NEWS_HASH_SALT},
            $userid,
            $newsid,
            $trackid,
            $valid_until,
            $url
        ),
        0,
        12
    );

    # se o hash bate, e ainda nao expirou o tempo de tracking
    if ($params->{h} eq $hash && $valid_until >= time()) {
        $c->schema2->resultset('NoticiasAbertura')->create(
            {
                track_id    => $valid_until . ':' . $trackid,
                cliente_id  => int($userid),
                noticias_id => $newsid,
                created_at  => \'NOW()',
            }
        );
    }

    $c->res->code(302);
    $c->redirect_to($url);
}

sub rebuild_index {
    my $c = shift;

    my $reindex = $c->schema2->resultset('Noticia')->search(
        {
            published => 'published',
        }
    )->update({indexed => '0'});

    $c->tick_rss_feeds();

    return $c->render(json => {reindex => $reindex});
}

1;
