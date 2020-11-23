package Penhas::Minion::Tasks::NewsIndexer;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Mojo::UserAgent;
use Penhas::KeyValueStorage;
use Mojo::URL;
use Scope::OnExit;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(news_indexer => \&news_indexer);
}

sub news_indexer {
    my ($job, $news_id) = @_;

    log_trace("minion:news_indexer", $news_id);

    my $logger = $job->app->log;
    my $kv     = $job->app->kv;
    my $schema = $job->app->schema2;

    my $filter_rs = $schema->resultset('Noticia')->search(
        {
            'me.id' => $news_id,
        }
    ) or die 'news not found';
    my $news = $filter_rs->search(
        undef,
        {
            prefetch => [
                {'rss_feed' => 'rss_feed_forced_tags'},
                'noticias2tags'
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->next;
    if ($news->{indexed} && !is_test()) {
        log_info("already indexed... skipping work");
        return $job->finish('skipped');
    }

    $news->{info} = from_json($news->{info});

    my @rules = $schema->resultset('TagIndexingConfig')->search(
        {
            ('me.status' => is_test() ? 'test' : 'prod'),
        },
        {
            prefetch => 'tag',
        }
    )->all;

    my $ua = Mojo::UserAgent->new;

    $ENV{MOJO_INSECURE} = 1;
    slog_info('Downloading %s...', $news->{hyperlink});
    my $response = $ua->get($news->{hyperlink}, {'User-Agent' => 'Indexador Feed RSS azmina.com.br'})->result;

    my $dom = $response->dom;
    if ($response->code != 200) {
        $filter_rs->update(
            {
                published  => 'error',
                indexed    => '1',
                indexed_at => \'NOW()',
                logs       => \[
                    "CONCAT(COALESCE(logs,''), ?)",
                    sprintf(
                        'hyperlink response did not returned status code 200: %s -- %s', $response->code,
                        substr($response->body, 0, 2000)
                    )
                ]
            }
        );
        return $job->finish('404');
    }

    my $og_image = $dom->at('meta[property="og:image"]');
    if ($og_image) {
        $og_image = $og_image->attr('content');
    }

    if ($og_image =~ /^\/\//) {
        $og_image = 'https:' . $og_image;
    }
    elsif ($og_image !~ /^https?\:\//) {
        my $ux = Mojo::URL->new($news->{hyperlink});
        $og_image = $ux->scheme() . '://' . $ux->host() . $og_image;
    }

    my $log = '';

    # cria uma sub valida apenas neste escopo, que tem acesso a variavel $log
    my $logthis = sub {
        my ($string, @other) = @_;
        my $text = sprintf $string, @other;
        log_info($text);
        $log .= $text . "\n";
    };

    my $tags = {};
    if ($news->{rss_feed}) {
        my @feed_tags = @{$news->{rss_feed}{rss_feed_forced_tags} || []};
        if (@feed_tags) {
            $logthis->('Adding tags from RSS feed (%d)', $news->{rss_feed}{id});

            foreach (@feed_tags) {
                $tags->{$_->{tag_id}}++;
                $logthis->('tag ' . $_->{tag_id} . ' added');
            }
        }
        else {
            $logthis->('No tags from RSS feed (%d)', $news->{rss_feed}{id});
        }
    }

    $logthis->('Testing rules...');

    my $cached_content;
    foreach my $rule (@rules) {
        my $compiled = $rule->compiled_regexp;
        next unless $compiled;    # pula invalidas

        my $tag_id = $rule->tag_id;
        $logthis->(
            'Tag Indexing Config (%d %s) tag %d %s', $rule->id, ($rule->description || ''), $rule->tag_id,
            $rule->tag->title
        );

        foreach my $test (
            qw/
            page_title_match
            html_article_match
            page_description_match
            url_match
            rss_feed_tags_match
            rss_feed_content_match
            /
          )
        {
            my $test_not = $test;
            $test_not =~ s/_match$/_not_match/;

            my $test_true  = $compiled->{$test};
            my $test_false = $compiled->{$test_not};

            next unless $test_true;

            my $content;
            if ($test eq 'page_title_match') {
                $content
                  = defined $cached_content->{$test}
                  ? $cached_content->{$test}
                  : ($dom->at('title')->text . ' ' . $news->{title});
            }
            elsif ($test eq 'html_article_match') {
                $content
                  = defined $cached_content->{$test}
                  ? $cached_content->{$test}
                  : ($dom->find('article *')->map('text')->join("\n"));
            }
            elsif ($test eq 'page_description_match') {
                $content
                  = defined $cached_content->{$test}
                  ? $cached_content->{$test}
                  : ($dom->find('meta[name="description"]')->map('to_string')->join("\n") . ' '
                      . ($news->{info}{description} || ''));
            }
            elsif ($test eq 'url_match') {
                $content = $news->{hyperlink};
            }
            elsif ($test eq 'rss_feed_tags_match') {
                $content
                  = exists $news->{info}{tags}
                  ? (ref $news->{info}{tags} eq 'ARRAY' ? join(' ', $news->{info}{tags}->@*) : $news->{info}{tags})
                  : '';
            }
            elsif ($test eq 'rss_feed_content_match') {
                $content = $news->{info}{content} || '';
            }
            $content = '' unless defined $content;
            $cached_content->{$test} = $content;

            slog_debug("\%s TRUE test is $test_true",   $test);
            slog_debug("\%s FALSE test is $test_false", $test) if $test_false;
            slog_debug('--> %s 「%s」',                   $test, $content || '(not set)');
            if (!$content) {
                $logthis->("$test content is empty, skipping matching column");
                next;
            }

            my $tested_true  = $content                       =~ $test_true;
            my $tested_false = defined $test_false ? $content =~ $test_false : 0;

            if ($tested_true && $tested_false) {
                $logthis->(" $test MATCHES but also $test_not also. Tag $tag_id WAS NOT added");
            }
            elsif ($tested_true) {
                $logthis->(" $test MATCHES Adding tag $tag_id");
                $tags->{$tag_id}++;
            }
            else {
                $logthis->(" $test not matched any rule");
            }
        }
    }

    $logthis->("\n" . 'Final tags for Noticia (%d) is %s', $news->{id}, join(', ', keys %$tags));

    my ($locked, $lock_key) = $kv->lock_and_wait('news_updater', 300);
    on_scope_exit { $kv->redis->del($lock_key) };
    die 'cannot get locked' unless $locked;

    $schema->txn_do(
        sub {
            $filter_rs->search_related_rs('noticias2tags')->delete;
            my @tags = keys %$tags;
            foreach my $tag_id (@tags) {
                $filter_rs->search_related_rs('noticias2tags')->create(
                    {
                        tag_id      => $tag_id,
                        noticias_id => $news->{id},
                    }
                );
            }

            $filter_rs->update(
                {
                    indexed_at      => \'NOW()',
                    published       => is_test() ? 'published:testing' : 'published',
                    indexed         => '1',
                    logs            => \["CONCAT(COALESCE(logs,''), ?)",            $log],
                    image_hyperlink => \["COALESCE(nullif(image_hyperlink,''), ?)", $og_image],
                    has_topic_tags  => (
                        scalar @tags
                        ? \[
                                "(SELECT count(1) FROM tags t WHERE t.id in ("
                              . join(',', ('?') x scalar @tags)
                              . ") AND t.is_topic = TRUE) > 0",
                            @tags
                          ]
                        : '0'
                    ),
                    tags_index => ',' . join(',', @tags) . ',',
                }
            );
        }
    );

    my $now = time();
    Penhas::KeyValueStorage->instance->redis->setex($ENV{REDIS_NS} . 'news_display_indexer.modtime', 3600, $now);

    # se outra noticia for indexada nos proximos 60 segundos, esse job nao sera executado
    # apenxas eh indexado apos 60 segundo sem entrar novas noticias
    my $job_id = $job->app->minion->enqueue(
        'news_display_indexer',
        [
            $now,
        ] => {
            delay => 60,
        }
    );
    slog_info('enqueued news_display_indexer in 60 seconds, job id %s with now=%s', $job_id, $now);

    return $job->finish('ok');
}

1;
