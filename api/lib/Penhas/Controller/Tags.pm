package Penhas::Controller::Tags;
use Mojo::Base 'Penhas::Controller';

use Penhas::Utils qw/is_test/;
use Penhas::KeyValueStorage;

sub filter_tags {
    my $c = shift;

    # limite bem generoso por IP, 60x por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(60, 60);

    my $tags = Penhas::KeyValueStorage->instance->redis_get_cached_or_execute(
        'tags_filter',
        86400,    # 1 day
        sub {
            my @tags = $c->schema2->resultset('Tag')->search(
                {
                    'me.status'          => is_test() ? 'test' : 'prod',
                    'me.show_on_filters' => '1',
                },
                {
                    columns => [
                        (qw/me.id me.title/),
                    ],
                    order_by     => 'me.title',
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            )->all;

            return {
                tags => \@tags,
            };
        }
    );

    return $c->render(json => $tags);
}

sub clear_cache {
    my $c     = shift;
    my $redis = Penhas::KeyValueStorage->instance->redis;

    $redis->del($ENV{REDIS_NS} . 'tags_filter', $ENV{REDIS_NS} . 'tags_highlight_regexp');

    return $c->render(json => {});
}

1;
