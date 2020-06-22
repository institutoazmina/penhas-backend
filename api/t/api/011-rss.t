use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use utf8;
use Penhas::Test;

my $t = test_instance;

$ENV{MAINTENANCE_SECRET} = '12345';

my $feed_rs      = app->schema2->resultset('RssFeed');
my $news_rs      = app->schema2->resultset('Noticia');
my $tags_rs      = app->schema2->resultset('Tag');
my $highlight_rs = app->schema2->resultset('TagsHighlight');
my $rules_rs     = app->schema2->resultset('TagIndexingConfig');

my $base = 'https://elasv2-api.appcivico.com/.tests-assets';

my $get_feed_url = sub { "$base/feed" . shift() . ".xml" };
my $get_page_url = sub { "$base/page" . shift() . ".html" };


my $random_cpf = 71380843669;

# apagando caso exista alguma coisa no banco
&clean_up;

my $feed1 = $feed_rs->create(
    {
        url            => $get_feed_url->('1'),
        status         => 'paused',
        fonte          => 'Fonte1',
        autocapitalize => '1'
    }
);

$ENV{FILTER_RSS_IDS} = $feed1->id;

my $forced_tag = $tags_rs->create(
    {
        status     => 'test',
        title      => 'forced',
        is_topic   => '0',
        created_at => \'NOW()',
    }
);
$feed1->add_to_rss_feed_forced_tags({tag_id => $forced_tag->id});

my $tag1 = $tags_rs->create(
    {
        status          => 'test',
        title           => 'tag1',
        is_topic        => '0',
        created_at      => \'NOW()',
        show_on_filters => 1,
    }
);
my $topic1 = $tags_rs->create(
    {
        status   => 'test', title      => 'topic1',
        is_topic => '1',    created_at => \'NOW()',
    }
);

$t->get_ok(
    '/filter-tags',
)->status_is(200)->json_is('/tags/0/title', 'tag1', 'tag 1')->json_is('/tags/1/title', undef, 'no more tags');

my $rule1 = $rules_rs->create(
    {
        status               => 'test',
        tag_id               => $topic1->id,
        regexp               => 1,
        page_title_match     => 'de',
        page_title_not_match => 'abc(\\',
    }
);
is $rule1->compiled_regexp, undef, 'is invalid';
$rule1->discard_changes;
like $rule1->error_msg, qr/page_title_not_match regexp error\: Trailing/, 'error ok';
$rule1->update({page_title_not_match => 'apoia pedido'});
is $rule1->compiled_regexp(), {
    page_title_not_match => qr/apoia pedido/iu,
    page_title_match     => qr/de/iu,
  },
  'regexp compiled';
$rule1->discard_changes;
is $rule1->error_msg, '',  'error_msg is empty';
is $rule1->verified,  '1', 'verified is true';

my $rule2 = $rules_rs->create(
    {
        status              => 'test',
        tag_id              => $tag1->id,
        regexp              => 0,
        rss_feed_tags_match => 'TAG3RSSONLY|tag1'
    }
);

$highlight_rs->create(
    {
        status    => 'test',
        tag_id    => $forced_tag->id,
        match     => 'shiranai',
        is_regexp => 1
    }
);

do {

    $t->get_ok(
        '/maintenance/tick-rss',
        form => {secret => $ENV{MAINTENANCE_SECRET}}
    )->status_is(200);

    my @news_full = $news_rs->search(
        {hyperlink => {'in' => [$get_page_url->('1'), $get_page_url->('2')]}},
        {order_by  => 'hyperlink', columns => ['id', 'title', 'fonte']}
    )->all;
    my @news = map { [$_->title, $_->fonte] } @news_full;
    is \@news,
      [
        ['This is Page1 Title', 'Fonte1'],
        ['This is Page2 Title', 'Fonte1'],
      ],
      'news insert is working, autocapitalize too';

    # atualiza pro feed1 com o titulo atualizado
    $feed1->update({url => $get_feed_url->('1_updated_titles')});

    is $news_rs->search({id => [map { $_->id() } @news_full]})->update({indexed => '1'}), 2, '2 rows updated';

    # roda novamente
    $t->get_ok(
        '/maintenance/tick-rss',
        form => {secret => $ENV{MAINTENANCE_SECRET}}
    )->status_is(200);

    @news = $news_rs->search(
        {hyperlink => {'in' => [$get_page_url->('1'), $get_page_url->('2')]}},
        {order_by  => 'hyperlink', columns => ['title', 'fonte', 'id']}
    )->all;

    is [
        [$news[0]->title, $news[0]->fonte],
        [$news[1]->title, $news[1]->fonte],
      ],
      [
        ['This is Page1 Title',                    'Fonte1'],
        ['Tachiagare. Dare mo Soba ni Inakutatte', 'Fonte1'],
      ],
      'news title update is working, autocapitalize too, keeping < 3 words lowercase';

    is test_get_minion_args_job(0), [$news[0]->id], 'page1 id is minion job 0';
    is test_get_minion_args_job(1), [$news[1]->id], 'page2 id is minion job 1';
    is test_get_minion_args_job(2), [$news[1]->id], 'page2 id is minion job 2 AGAIN (title changed)';

    trace_popall;
    my $job = Minion::Job->new(id => fake_int(1, 99)->(), minion => $t->app->minion, task => 'news_indexer');
    ok(Penhas::Minion::Tasks::NewsIndexer::news_indexer($job, test_get_minion_args_job(0)), 'indexing news 0');

    is trace_popall, 'minion:news_indexer,' . $news[0]->id, 'job processed';

    is [sort map { $_->tag_id } $news[0]->noticias2tags->all], [$forced_tag->id, $topic1->id],
      'tags match expected [forced from feed + topic1 from rule because page_title_match match "de"]';
    $news[0]->discard_changes;
    is $news[0]->published, 'published', 'status is published';

    ok(Penhas::Minion::Tasks::NewsIndexer::news_indexer($job, test_get_minion_args_job(1)), 'indexing news 1');

    is [sort map { $_->tag_id } $news[1]->noticias2tags->all], [$forced_tag->id],
      'tags match expected [forced from feed only]';
    $news[0]->discard_changes;
    is $news[0]->published, 'published', 'status is published';

    local $ENV{PUBLIC_API_URL} = '/';

    my $tweets = [
        {content => 'keep as it is'},
        {content => 'mod because cited shiraNAI in the text shiranai'},
        {content => 'notshiranai is not wordbreaking'}
    ];
    app->add_tweets_highlights(user => {id => 0}, tweets => $tweets);

    use DDP;
    p $tweets;
    is $tweets->[0]{content}, 'keep as it is';
    is $tweets->[1]{content},
      'mod because cited <span style="color: #f982b4">shiraNAI</span> in the text <span style="color: #f982b4">shiranai</span>';
    is $tweets->[3]{content}, 'notshiranai is not wordbreaking';

    like(my $tracking_url = $tweets->[2]{news}[0]{href}, qr/news-redirect/, 'tracking url');
    is($tweets->[2]{type}, 'related_news', 'related_news type');

    ok($tracking_url, 'has $tracking_url') and $t->get_ok($tracking_url)->status_is(302);

    ok(
        Penhas::Minion::Tasks::NewsDisplayIndexer::news_display_indexer($job, test_get_minion_args_job(4)),
        'display indexing'
    );

    my ($session, $user_id) = get_user_session($random_cpf);
    $Penhas::Helpers::Timeline::ForceFilterClientes = [$user_id];
    $t->get_ok(
        ('/timeline?category=only_news'),
        {'x-api-key' => $session}
    )->status_is(200);

    on_scope_exit { user_cleanup(user_id => $user_id); };

};
done_testing();

# &clean_up;

exit;

sub clean_up {
    my $noticias = $news_rs->search({hyperlink => {'like' => $base . '%'}});

    app->schema2->resultset('NoticiasAbertura')
      ->search({noticias_id => {'in' => $noticias->get_column('id')->as_query}})->delete;

    $noticias->delete;
    $feed_rs->search({url => {'like' => $base . '%'}})->delete;
    $highlight_rs->search({status => 'test'})->delete;
    $rules_rs->search({status => 'test'})->delete;
    $tags_rs->search({status => 'test'})->delete;
}