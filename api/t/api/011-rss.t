use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;

my $t = test_instance;

$ENV{MAINTENANCE_SECRET} = '12345';

my $feed_rs = app->schema2->resultset('RssFeed');
my $news_rs = app->schema2->resultset('Noticia');


my $base = 'https://elasv2-api.appcivico.com/.tests-assets';

my $get_feed_url = sub { "$base/feed" . shift() . ".xml" };
my $get_page_url = sub { "$base/page" . shift() . ".html" };

# apagando caso exista alguma coisa no banco
$news_rs->search({hyperlink => {'in' => [$get_page_url->('1'), $get_page_url->('2')]}})->delete;
$feed_rs->search({url       => {'in' => [$get_feed_url->('1'), $get_feed_url->('1_updated_titles'),]}})->delete;

my $feed1 = $feed_rs->create(
    {
        url            => $get_feed_url->('1'),
        status         => 'paused',
        fonte          => 'Fonte1',
        autocapitalize => '1'
    }
);

$ENV{FILTER_RSS_IDS} = $feed1->id;

subtest_buffered 'Populate news using RSS' => sub {

    $t->get_ok(
        '/maintenance/tick-rss',
        form => {secret => $ENV{MAINTENANCE_SECRET}}
    )->status_is(200);

    my @news = map { [$_->title, $_->fonte] } $news_rs->search(
        {hyperlink => {'in' => [$get_page_url->('1'), $get_page_url->('2')]}},
        {order_by  => 'hyperlink', columns => ['title', 'fonte']}
    )->all;
    is \@news,
      [
        ['This is Page1 Title', 'Fonte1'],
        ['This is Page2 Title', 'Fonte1'],
      ],
      'news insert is working, autocapitalize too';

    # atualiza pro feed1 com o titulo atualizado
    $feed1->update({url => $get_feed_url->('1_updated_titles')});

    # roda novamente
    $t->get_ok(
        '/maintenance/tick-rss',
        form => {secret => $ENV{MAINTENANCE_SECRET}}
    )->status_is(200);

    @news = map { [$_->title, $_->fonte] } $news_rs->search(
        {hyperlink => {'in' => [$get_page_url->('1'), $get_page_url->('2')]}},
        {order_by  => 'hyperlink', columns => ['title', 'fonte']}
    )->all;
    is \@news,
      [
        ['This is Page1 Title',                    'Fonte1'],
        ['Tachiagare. Dare mo Soba ni Inakutatte', 'Fonte1'],
      ],
      'news title update is working, autocapitalize too, keeping < 3 words lowercase';


};
done_testing();

exit;
