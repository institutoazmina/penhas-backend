package Penhas::Controller::Tags;
use utf8;
use Mojo::Base 'Penhas::Controller';
use Penhas::Controller::Me;
use Penhas::Utils qw/is_test/;
use Penhas::KeyValueStorage;

sub filter_tags {
    my $c = shift;

    Penhas::Controller::Me::check_and_load($c);

    my $modules = $c->stash('user_obj')->access_modules_str;

    my $cache_key = '';
    $cache_key .= 'T' if $modules =~ /,tweets,/;
    $cache_key .= 'N' if $modules =~ /,noticias,/;

    my $tags = Penhas::KeyValueStorage->instance->redis_get_cached_or_execute(
        "tags_filter:$cache_key",
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
                tags       => \@tags,
                categories => [
                    {default => 1, value => 'all', label => 'Tudo',},
                    (
                        $modules =~ /,noticias,/
                        ? (
                            {default => 0, value => 'only_news', label => 'Apenas notícias',},
                          )
                        : ()
                    ),
                    (
                        $modules =~ /,tweets,/
                        ? (
                            {default => 0, value => 'only_tweets', label => 'Apenas publicações',},
                            {default => 0, value => 'all_myself',  label => 'Minhas publicações e comentários',},
                          )
                        : ()
                    )
                ],
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
