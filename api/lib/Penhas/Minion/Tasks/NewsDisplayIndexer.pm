package Penhas::Minion::Tasks::NewsDisplayIndexer;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Mojo::UserAgent;
use Penhas::KeyValueStorage;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(news_display_indexer => \&news_display_indexer);
}

sub news_display_indexer {
    my ($job, $modtime) = @_;

    my $schema = $job->app->schema2;

    my $redis       = Penhas::KeyValueStorage->instance->redis;
    my $cur_modtime = $redis->get($ENV{REDIS_NS} . 'news_display_indexer.modtime');
    if ($cur_modtime && $modtime ne $cur_modtime) {
        log_info("news_display_indexer is skipped because: modtime $modtime already outdated by $cur_modtime");
        return $job->finish('skipped');
    }
    slog_info("recalculing news_display_indexer as modtime %s", $modtime);
    log_trace("minion:news_display_indexer", $modtime);

    my @topic_news = $schema->resultset('Tag')->search(
        {

            'me.status'         => is_test() ? 'test' : 'prod',
            'me.is_topic'       => 1,
            'noticia.published' => is_test() ? 'published:testing' : 'published',
        },
        {
            join     => {'noticias_tags' => 'noticia'},
            prefetch => 'noticias_tags',
            columns  => [
                'me.id',
                'me.title',
                'noticias_tags.id',
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            order_by     => ['me.topic_order', 'me.title', {'-desc' => 'noticia.display_created_time'}]
        }
    )->all;

    my @display;
    my $order = 0;

    my $has_news = 1;
    while ($has_news) {

        my $added = 0;
        foreach my $topic (@topic_news) {
            my @group = splice($topic->{noticias_tags}->@*, 0, 3);

            if (@group) {

                push @display, {
                    order    => $order,
                    noticias => to_json([map { $_->{noticias_id} } @group]),
                    meta     => to_json(
                        {
                            title   => $topic->{title},
                            tags_id => ',' . $topic->{id} . ',',
                        }
                    ),
                    status     => is_test() ? 'test' : 'prod',
                    created_at => \'NOW()',
                };
                $order++;
                $added++;
            }
        }

        $has_news = $added > 0 ? 1 : 0;

    }

    $schema->txn_do(
        sub {
            my $rs = $schema->resultset('NoticiasVitrine')->search(
                {
                    'me.status' => is_test() ? 'test' : 'prod',
                }
            );
            $rs->delete;

            $rs->populate(\@display);

        }
    );


    return $job->finish('ok');
}

1;
