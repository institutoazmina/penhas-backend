package Penhas::Helpers::RSS;
use common::sense;
use Carp qw/croak confess/;
use Digest::MD5 qw/md5_hex/;
use Penhas::Utils qw/tt_test_condition tt_render is_test/;
use JSON;
use utf8;
use warnings;
use DateTime;
use Penhas::Logger;
use Scope::OnExit;
use Mojo::Feed;

use Mojo::DOM;
use Penhas::KeyValueStorage;

sub setup {
    my $self = shift;

    $self->helper('tick_rss_feeds' => sub { &tick_rss_feeds(@_) });
}

sub tick_rss_feeds {
    my ($c) = @_;


    my $now       = DateTime->now;
    my $next_tick = $now->add({hours => $ENV{RSS_TICK_EACH_N_HOURS} || 3});

    my $feeds_rs = $c->schema2->resultset('RssFeed')->search(
        {
            (
                $ENV{FILTER_RSS_IDS}
                ? (id => {'in' => [split /\,/, $ENV{FILTER_RSS_IDS}]})
                : (
                    'status' => 'active',
                    '-or'    => [
                        {'next_tick' => undef},
                        {'next_tick' => {'<=' => $now->datetime}}
                    ]
                )
            )
        }
    );

    my @news;
    while (my $feed = $feeds_rs->next) {
        slog_info('Downloading feed id %s url %s', $feed->id, $feed->url);

        my $rss = Mojo::Feed->new(url => $feed->url);
        $rss->items->each(
            sub {
                my $info = $_->to_hash();

                my $link      = lc delete $info->{link};
                my $title     = delete $info->{title};
                my $published = delete $info->{published};

                # o ID nao precisa ir pro index, e geralmente ele eh a propria URL
                delete $info->{guid};
                delete $info->{id};

                next unless $link =~ /^https?\:\/\//;    # precisa ser http ou https
                next unless $title;                      # precisa ter um titulo

                $title = substr($title, 0, 2000);

                slog_info('found link "%s" with title "%s"', $link, $title);

                if ($feed->autocapitalize) {
                    $title = ucfirst(lc($title));

                    # apenas palavras com mais de 3 chars
                    $title =~ s/(\s)(.[^\s]{3})/$1 . ucfirst($2)/eg;

                    # colocar upper case novamente depois de . ou ;
                    $title =~ s/(\.\s+)(.)/$1 . ucfirst($2)/eg;

                    slog_info('autocapitalize title to "%s"', $title);
                }

                push @news, {
                    link      => $link,
                    title     => $title,
                    published => $published,

                    rss_feed_id => $feed->id,
                    fonte       => $feed->fonte,
                    info        => $info,
                };
            }
        );
        $feed->update(
            {
                last_run  => $now->datetime,
                next_tick => $next_tick->datetime,
            }
        );
    }

    use DDP;
    p \@news;

    my $news_rs      = $c->schema2->resultset('Noticia');
    my @current_news = $news_rs->search(
        {hyperlink => {'in' => [map { $_->{link} } @news]}},
        {
            columns      => ['hyperlink', 'title', 'id', 'rss_feed_id'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    );
    my %map_exists = map { $_->{hyperlink} => $_ } @current_news;

    my @jobs;
    foreach my $news (@news) {
        my $info = $news->{info};
        if (exists $map_exists{$news->{link}}) {
            my $row = $map_exists{$news->{link}};

            # [se mudou o title]
            # && [e continua no mesmo feed_id, vai que alguem cadastra duas vezes o mesmo feed]
            # reindexar noticia
            if ($row->{title} ne $news->{title} && $row->{rss_feed_id} eq $news->{rss_feed_id}) {
                slog_info('news id %d will be reindexed [title changed]', $row->{id});
                $info = &_process_info($info);
                $news_rs->find($row->{id})->update(
                    {
                        title   => $news->{title},
                        indexed => '0',
                        info    => to_json($info),
                    }
                );
                push @jobs, $row->{id};
            }
            next;
        }

        my $pub_date = $now;

        # se foi definido data de publicacao, usa ela no lugar do now
        # precisa ser um Epoch
        if ($news->{published} && $news->{published} =~ /^\d+$/a) {
            $pub_date = DateTime->from_epoch(epoch => $news->{published});
        }
        else {
            slog_info('published is not valid: link="%s" published="%s"', $news->{link}, $news->{published} || '');
        }

        $info = &_process_info($info);

        my $row = $news_rs->create(
            {
                hyperlink            => $news->{link},
                title                => $news->{title},
                indexed              => '0',
                rss_feed_id          => $news->{rss_feed_id},
                fonte                => $news->{fonte},
                info                 => to_json($info),
                created_at           => $now->datetime,
                display_created_time => $pub_date->datetime,
                author               => substr($info->{author} || '', 0, 200),
                published            => 'hidden', # aguardar ate ser indexada
                description          => (
                    $info->{description} && length($info->{description}) > 2000
                    ? substr($info->{description}, 0, 2000) . '...'
                    : $info->{description}
                ),
            }
        );
        slog_info('news row id %d inserted successfully', $row->id);
        push @jobs, $row->id;
    }

    foreach my $job (@jobs) {
        slog_info('Adding news id=%s to be indexed', $job);

    }

}


sub _process_info {
    my ($info) = @_;

    my $content     = delete $info->{content};
    my $description = delete $info->{description};

    # se ambos tem valor, mas sao identicos, o conteudo nao eh necessario
    if ($content && $description && $description eq $content) {
        $content = '';
    }

    # Remove HTML
    if ($content && $content =~ /\</) {
        $content = Mojo::DOM->new($content)->all_text;
    }

    if ($description && $description =~ /\</) {
        $description = Mojo::DOM->new($description)->all_text;
    }

    $info->{description} = $description;
    $info->{content}     = $content;

    return $info;
}
1;

__END__


use v5.24;
use Mojo::File qw(path);


#$my $feed = Mojo::Feed->new(url => "http://feeds.feedburner.com/blogmacmagazine");
#my $feed = Mojo::Feed->new(url => "https://azmina.com.br/tag/mulheres-no-congresso/feed/");
my $feed = Mojo::Feed->new(url => "http://rss.home.uol.com.br/index.xml");

say $feed->title;
$feed->items->each(
    sub {
        use DDP;
        p $_->link;
        say $_->title, q{ }, Mojo::Date->new($_->published);
    }
);