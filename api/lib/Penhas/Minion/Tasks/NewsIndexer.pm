package Penhas::Minion::Tasks::NewsIndexer;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Mojo::UserAgent;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(news_indexer => \&news_indexer);
}

sub news_indexer {
    my ($job, $news_id) = @_;

    log_trace("minion:news_indexer", $news_id);

    my $logger = $job->app->log;
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
            (status => is_test() ? 'test' : 'prod'),
        }
    )->all;

    my $ua = Mojo::UserAgent->new;

    slog_info('Downloading %s...', $news->{hyperlink});
    my $response = $ua->get($news->{hyperlink})->result;

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
        $logthis->('Adding tags from RSS feed (%d): ', $news->{rss_feed}{id});
        foreach (@{$news->{rss_feed}{rss_feed_forced_tags} || []}) {
            $tags->{$_->{tag_id}}++;
            $logthis->($_->{tag_id} . ' added');
        }
    }

    my $cached_content;
    foreach my $rule (@rules) {
        my $compiled = $rule->compiled_regexp;
        next unless $compiled;    # pula invalidas

        my $tag_id = $rule->tag_id;
        $logthis->('Tag Indexing Config (%d, tag %d): %s', $rule->id, $rule->tag_id, $rule->description||'');

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
                  use DDP; p $content; p $news;
            }
            elsif ($test eq 'rss_feed_content_match') {
                $content = $news->{info}{content} || '';
            }
            $content = '' unless defined $content;
            $cached_content->{$test} = $content;

            slog_debug('%s content is 「%s」', $test, $content || 'empty');
            if (!$content) {
                $logthis->("$test content is empty, match skiped.");
                next;
            }

            my $tested_true  = $content                       =~ $test_true;
            my $tested_false = defined $test_false ? $content =~ $test_false : 0;

            if ($tested_true && $tested_false) {
                $logthis->("$test MATCHES but also $test_not also. Tag $tag_id NOT Added");
            }
            elsif ($tested_true) {
                $logthis->("$test MATCHES Adding tag $tag_id");
                $tags->{$tag_id}++;
            }
            else {
                $logthis->("$test not matched");
            }
        }
    }

    $logthis->("\n" . 'Final tags for Noticia (%d) is %s', $news->{id}, join(', ', keys %$tags));


    $schema->txn_do(
        sub {
            $filter_rs->search_related_rs('noticias2tags')->delete;
            foreach my $tag_id (keys %$tags) {
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
                    published       => 'published',
                    indexed         => '1',
                    logs            => \["CONCAT(COALESCE(logs,''), ?)", $log],
                    image_hyperlink => \["COALESCE(nullif(image_hyperlink,''), ?)", $og_image],
                }
            );
        }
    );

    return $job->finish('ok');
}

1;
